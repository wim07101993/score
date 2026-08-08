package set

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"score/internal/auth"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
)

// pgErrForeignKeyViolation is the postgres error code for a row pointing at
// something that is not there, which for a set entry means a score that does
// not exist.
const pgErrForeignKeyViolation = "23503"

type DatabaseFactory func(ctx context.Context) (*Database, error)

type Database struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewDatabase(logger *slog.Logger, conn *pgxpool.Conn) *Database {
	return &Database{logger: logger, conn: conn}
}

func (db *Database) Dispose() {
	db.conn.Release()
}

// ------------------------------------
//	MUTATING FUNCTIONS
// ------------------------------------

func (db *Database) SaveSet(ctx context.Context, id string, user *auth.UserInfo, write WriteSet) error {
	db.logger.Info("saving set", slog.String("id", id))

	if err := validate(write); err != nil {
		return err
	}

	tx, err := db.conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const ownerQuery = `SELECT owner_subject FROM sets WHERE id = @id`
	var owner string
	err = tx.QueryRow(ctx, ownerQuery, pgx.NamedArgs{"id": id}).Scan(&owner)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// A set that is not there yet belongs to whoever is creating it.
		owner = user.Subject
	case err != nil:
		return err
	case owner != user.Subject:
		return ErrNotSetOwner
	}

	const upsertSetQuery = `
		INSERT INTO sets (id, owner_subject, title, description, lastChangedAt, deletedAt)
		VALUES (@id, @owner_subject, @title, @description, @lastChangedAt, NULL)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			lastChangedAt = EXCLUDED.lastChangedAt,
			-- Writing a set again brings it back: a client that still has it
			-- and edits it is saying it should exist.
			deletedAt = NULL`

	_, err = tx.Exec(ctx, upsertSetQuery, pgx.NamedArgs{
		"id":            id,
		"owner_subject": owner,
		"title":         write.Title,
		"description":   write.Description,
		"lastChangedAt": time.Now().UTC(),
	})
	if err != nil {
		return err
	}

	// The entries are replaced rather than merged: they are an ordered list,
	// and what the client sends is the whole of it.
	_, err = tx.Exec(ctx, `DELETE FROM set_entries WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": id})
	if err != nil {
		return err
	}

	const insertEntryQuery = `
		INSERT INTO set_entries (id, set_id, position, score_id, description, transposition, hidden_parts)
		VALUES (@id, @set_id, @position, @score_id, @description, @transposition, @hidden_parts)`

	for position, entry := range write.Entries {
		_, err = tx.Exec(ctx, insertEntryQuery, pgx.NamedArgs{
			"id":            entry.Id,
			"set_id":        id,
			"position":      position,
			"score_id":      entry.ScoreId,
			"description":   entry.Description,
			"transposition": entry.Transposition,
			"hidden_parts":  emptyWhenNil(entry.HiddenParts),
		})
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == pgErrForeignKeyViolation {
				return &ErrUnknownScore{ScoreId: entry.ScoreId}
			}
			return err
		}
	}

	_, err = tx.Exec(ctx, `DELETE FROM set_shares WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": id})
	if err != nil {
		return err
	}
	for _, email := range normalizedShares(write.SharedWith, user.Email) {
		_, err = tx.Exec(ctx,
			`INSERT INTO set_shares (set_id, email) VALUES (@set_id, @email) ON CONFLICT DO NOTHING`,
			pgx.NamedArgs{"set_id": id, "email": email})
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

// DeleteSet marks a set as deleted without removing it, so that clients holding
// a copy learn that it is gone rather than syncing it back.
func (db *Database) DeleteSet(ctx context.Context, id string, user *auth.UserInfo) error {
	db.logger.Info("deleting set", slog.String("id", id))

	const query = `
		UPDATE sets
		SET deletedAt = @deletedAt, lastChangedAt = @lastChangedAt
		WHERE id = @id AND owner_subject = @owner_subject AND deletedAt IS NULL`

	now := time.Now().UTC()
	tag, err := db.conn.Exec(ctx, query, pgx.NamedArgs{
		"id":            id,
		"owner_subject": user.Subject,
		"deletedAt":     now,
		"lastChangedAt": now,
	})
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		// Either it is not there, already gone, or not theirs. Telling the
		// three apart would say more about other people's sets than it should.
		return ErrSetNotFound
	}
	return nil
}

// ------------------------------------
//	QUERY FUNCTIONS
// ------------------------------------

func (db *Database) GetSet(ctx context.Context, id string, user *auth.UserInfo) (*Set, error) {
	db.logger.Info("getting set", slog.String("id", id))

	const query = selectSets + `
		WHERE s.id = @id
			AND (s.owner_subject = @subject OR sh.email IS NOT NULL)
			AND s.deletedAt IS NULL`

	rows, err := db.conn.Query(ctx, query, pgx.NamedArgs{
		"id":      id,
		"subject": user.Subject,
		"email":   user.Email,
	})
	if err != nil {
		return nil, err
	}

	sets, err := scanSets(rows, user)
	if err != nil {
		return nil, err
	}
	if len(sets) == 0 {
		return nil, ErrSetNotFound
	}

	if err := db.fillIn(ctx, sets, user); err != nil {
		return nil, err
	}
	return sets[0], nil
}

func (db *Database) GetSets(ctx context.Context, user *auth.UserInfo, changesSince, changesUntil time.Time) ([]*Set, error) {
	db.logger.Info("getting sets")

	const query = selectSets + `
		WHERE (s.owner_subject = @subject OR sh.email IS NOT NULL)
			AND s.lastChangedAt >= @since AND s.lastChangedAt <= @until
		ORDER BY s.lastChangedAt DESC`

	rows, err := db.conn.Query(ctx, query, pgx.NamedArgs{
		"subject": user.Subject,
		"email":   user.Email,
		"since":   changesSince,
		"until":   changesUntil,
	})
	if err != nil {
		return nil, err
	}

	sets, err := scanSets(rows, user)
	if err != nil {
		return nil, err
	}
	if err := db.fillIn(ctx, sets, user); err != nil {
		return nil, err
	}
	return sets, nil
}

const selectSets = `
	SELECT s.id, s.owner_subject, s.title, s.description, s.lastChangedAt, s.deletedAt
	FROM sets AS s
	LEFT JOIN set_shares AS sh ON sh.set_id = s.id AND sh.email = @email`

func scanSets(rows pgx.Rows, user *auth.UserInfo) ([]*Set, error) {
	defer rows.Close()

	sets := make([]*Set, 0)
	for rows.Next() {
		var (
			id            string
			ownerSubject  string
			title         string
			description   string
			lastChangedAt time.Time
			deletedAt     *time.Time
		)
		if err := rows.Scan(&id, &ownerSubject, &title, &description, &lastChangedAt, &deletedAt); err != nil {
			return nil, err
		}

		sets = append(sets, &Set{
			Id:            id,
			Title:         title,
			Description:   description,
			Entries:       make([]Entry, 0),
			SharedWith:    make([]string, 0),
			IsOwner:       ownerSubject == user.Subject,
			LastChangedAt: lastChangedAt,
			DeletedAt:     deletedAt,
		})
	}
	return sets, rows.Err()
}

// fillIn reads the entries and shares of the given sets.
func (db *Database) fillIn(ctx context.Context, sets []*Set, user *auth.UserInfo) error {
	if len(sets) == 0 {
		return nil
	}

	byId := make(map[string]*Set, len(sets))
	ids := make([]string, 0, len(sets))
	for _, s := range sets {
		byId[s.Id] = s
		ids = append(ids, s.Id)
	}

	const entriesQuery = `
		SELECT set_id, id, score_id, description, transposition, hidden_parts
		FROM set_entries
		WHERE set_id = ANY(@ids)
		ORDER BY set_id, position`

	rows, err := db.conn.Query(ctx, entriesQuery, pgx.NamedArgs{"ids": ids})
	if err != nil {
		return err
	}
	for rows.Next() {
		var (
			setId         string
			entry         Entry
			transposition int16
			hiddenParts   pgtype.Array[string]
		)
		if err := rows.Scan(&setId, &entry.Id, &entry.ScoreId, &entry.Description, &transposition, &hiddenParts); err != nil {
			rows.Close()
			return err
		}
		entry.Transposition = int(transposition)
		entry.HiddenParts = emptyWhenNil(hiddenParts.Elements)

		if s := byId[setId]; s != nil {
			s.Entries = append(s.Entries, entry)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}

	// Who else a set is shared with is only the owner's business.
	const sharesQuery = `
		SELECT sh.set_id, sh.email
		FROM set_shares AS sh
		JOIN sets AS s ON s.id = sh.set_id
		WHERE sh.set_id = ANY(@ids) AND s.owner_subject = @subject
		ORDER BY sh.email`

	shareRows, err := db.conn.Query(ctx, sharesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
	if err != nil {
		return err
	}
	defer shareRows.Close()
	for shareRows.Next() {
		var setId, email string
		if err := shareRows.Scan(&setId, &email); err != nil {
			return err
		}
		if s := byId[setId]; s != nil {
			s.SharedWith = append(s.SharedWith, email)
		}
	}
	return shareRows.Err()
}

// ------------------------------------
//	HELPERS
// ------------------------------------

func validate(write WriteSet) error {
	seen := make(map[string]struct{}, len(write.Entries))
	for i, entry := range write.Entries {
		if entry.Id == "" {
			return &ErrInvalidSet{Reason: fmt.Sprintf("entry %d has no id", i)}
		}
		if _, duplicate := seen[entry.Id]; duplicate {
			// The same score may be in a set twice, but each time it is is its
			// own entry with its own id, description and key.
			return &ErrInvalidSet{Reason: fmt.Sprintf("entry id %s is used more than once", entry.Id)}
		}
		seen[entry.Id] = struct{}{}

		if entry.ScoreId == "" {
			return &ErrInvalidSet{Reason: fmt.Sprintf("entry %d has no score", i)}
		}
		if entry.Transposition < MinTransposition || entry.Transposition > MaxTransposition {
			return &ErrInvalidSet{Reason: fmt.Sprintf(
				"entry %d is transposed by %d semitones, which is outside the range %d..%d",
				i, entry.Transposition, MinTransposition, MaxTransposition)}
		}
	}
	return nil
}

// normalizedShares tidies the addresses a set is shared with: they are lowered
// so that looking one up is a plain comparison, blanks are dropped, and the
// owner is not shared with, since they already have it.
func normalizedShares(emails []string, ownerEmail string) []string {
	seen := make(map[string]struct{}, len(emails))
	shares := make([]string, 0, len(emails))

	for _, email := range emails {
		normalized := auth.NormalizeEmail(email)
		if normalized == "" || normalized == ownerEmail {
			continue
		}
		if _, duplicate := seen[normalized]; duplicate {
			continue
		}
		seen[normalized] = struct{}{}
		shares = append(shares, normalized)
	}
	return shares
}

func emptyWhenNil(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}

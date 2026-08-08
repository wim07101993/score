package set

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

// Save creates or replaces a set.
//
// A set that is not there yet belongs to whoever writes it; one that is can
// only be written by its owner, which is ErrNotSetOwner. It answers
// ErrInvalidSet for a set the caller has to fix, and ErrUnknownScore for an
// entry pointing at a score that does not exist.
//
// The whole of it is one transaction: a set is its title, its entries and its
// shares together, and half of a replacement is not a set anybody asked for.
func Save(ctx context.Context, db *pgxpool.Conn, setId string, user User, write WriteSet) error {
	slogctx.Info(ctx, "saving set", slog.String("setId", setId))

	if err := validate(write); err != nil {
		return err
	}

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const ownerQuery = `SELECT owner_subject FROM sets WHERE id = @id`
	var owner string
	err = tx.QueryRow(ctx, ownerQuery, pgx.NamedArgs{"id": setId}).Scan(&owner)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// A set that is not there yet belongs to whoever is creating it.
		owner = user.Subject
	case err != nil:
		return fmt.Errorf("failed to look up the owner of the set: %w", err)
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
		"id":            setId,
		"owner_subject": owner,
		"title":         write.Title,
		"description":   write.Description,
		"lastChangedAt": time.Now().UTC(),
	})
	if err != nil {
		return fmt.Errorf("failed to save the set: %w", err)
	}

	// The entries are replaced rather than merged: they are an ordered list,
	// and what the client sends is the whole of it.
	_, err = tx.Exec(ctx, `DELETE FROM set_entries WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": setId})
	if err != nil {
		return fmt.Errorf("failed to clear the entries of the set: %w", err)
	}

	const insertEntryQuery = `
		INSERT INTO set_entries (id, set_id, position, score_id, description, transposition, hidden_parts)
		VALUES (@id, @set_id, @position, @score_id, @description, @transposition, @hidden_parts)`

	for position, entry := range write.Entries {
		_, err = tx.Exec(ctx, insertEntryQuery, pgx.NamedArgs{
			"id":            entry.Id,
			"set_id":        setId,
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
			return fmt.Errorf("failed to save an entry of the set: %w", err)
		}
	}

	_, err = tx.Exec(ctx, `DELETE FROM set_shares WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": setId})
	if err != nil {
		return fmt.Errorf("failed to clear the shares of the set: %w", err)
	}
	for _, email := range normalizedShares(write.SharedWith, user.Email) {
		_, err = tx.Exec(ctx,
			`INSERT INTO set_shares (set_id, email) VALUES (@set_id, @email) ON CONFLICT DO NOTHING`,
			pgx.NamedArgs{"set_id": setId, "email": email})
		if err != nil {
			return fmt.Errorf("failed to share the set: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the set: %w", err)
	}
	return nil
}

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
		normalized := NormalizeEmail(email)
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

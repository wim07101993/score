// Package set holds the sets a user plays a gig from: an ordered list of
// scores, each with the key it is played in and the parts that are on screen.
//
// A set says how a score is played, never what it is. Nothing here writes to a
// score, and two sets can play the same score in different keys without either
// of them changing it.
//
// Like internal/score, it knows nothing about how any of this is served. There
// is a file per thing the API asks of it, holding the queries that answer it,
// and what comes back is this package's own model of a set. Turning that into a
// response, and a failure from here into an answer for a caller, is
// internal/server's job.
package set

import (
	"context"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// pgErrForeignKeyViolation is the postgres error code for a row pointing at
// something that is not there, which for a set entry means a score that does
// not exist.
const pgErrForeignKeyViolation = "23503"

// User is who is asking after a set. A set belongs to someone by subject and is
// shared with them by address, so telling what someone may see takes both.
//
// It is this package's own idea of a caller rather than the one the auth layer
// hands around, so that nothing down here has to know how somebody proved who
// they are. Build one with NewUser rather than by hand: the address has to be
// in the form shares are compared in, and NewUser is what puts it there.
type User struct {
	Subject string
	Email   string
}

// NewUser is how a caller from the auth layer becomes one this package can
// compare shares against.
func NewUser(subject, email string) User {
	return User{Subject: subject, Email: NormalizeEmail(email)}
}

// NormalizeEmail puts an address in the one form shares are stored and compared
// in. Addresses are handed around by people typing them, so the case they
// arrive in says nothing about who they belong to.
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// selectSets is the head of both the lookup of one set and the listing of a
// window of them: they select the same columns, in the order scanSets reads
// them, and differ only in what they filter by.
//
// The join is what makes a share readable: a row survives it when the caller
// owns the set or their address is on it, and `sh.email IS NOT NULL` in the
// clauses below is how the second of those is asked.
const selectSets = `
	SELECT s.id, s.owner_subject, s.title, s.description, s.lastChangedAt, s.deletedAt
	FROM sets AS s
	LEFT JOIN set_shares AS sh ON sh.set_id = s.id AND sh.email = @email`

func scanSets(rows pgx.Rows, user User) ([]*Set, error) {
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

		// The store hands a moment back in whatever zone the process runs in.
		// Which one that is says nothing about the set, and letting it through
		// would have the same set read differently from one deployment to the
		// next, so it is said in UTC and the instant is what is left.
		lastChangedAt = lastChangedAt.UTC()
		if deletedAt != nil {
			utc := deletedAt.UTC()
			deletedAt = &utc
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

// fillIn reads the entries and shares of the given sets. It is one query for
// all of them rather than one per set, so that listing a window costs the same
// three round trips however many sets are in it.
func fillIn(ctx context.Context, db *pgxpool.Conn, sets []*Set, user User) error {
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

	rows, err := db.Query(ctx, entriesQuery, pgx.NamedArgs{"ids": ids})
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

	// Who else a set is shared with is only the owner's business, which is what
	// the join on owner_subject says: for a set that is merely shared with the
	// caller, no row comes back and SharedWith stays empty.
	const sharesQuery = `
		SELECT sh.set_id, sh.email
		FROM set_shares AS sh
		JOIN sets AS s ON s.id = sh.set_id
		WHERE sh.set_id = ANY(@ids) AND s.owner_subject = @subject
		ORDER BY sh.email`

	shareRows, err := db.Query(ctx, sharesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
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

// emptyWhenNil keeps an absent list an empty list rather than a null, so that a
// client never has to tell the two apart.
func emptyWhenNil(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}

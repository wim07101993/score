package set

import (
	"context"
	"fmt"
	"log/slog"
	"slices"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

func Get(ctx context.Context, db *pgxpool.Conn, setId string, user User) (*Set, error) {
	slogctx.Info(ctx, "getting set", slog.String("setId", setId))

	const query = selectSets + `
		WHERE id = @id
			AND (owner_subject = @subject OR shared)
			AND deletedAt IS NULL`

	rows, err := db.Query(ctx, query, pgx.NamedArgs{
		"id":      setId,
		"subject": user.Subject,
		"email":   user.Email,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query database: %w", err)
	}

	sets, err := scanSets(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan set db row: %w", err)
	}
	if len(sets) == 0 {
		return nil, ErrSetNotFound
	}

	if err := fillIn(ctx, db, sets, user); err != nil {
		return nil, fmt.Errorf("failed to read the entries and shares of the set: %w", err)
	}
	return sets[0], nil
}

func List(
	ctx context.Context,
	db *pgxpool.Conn,
	user User,
	changesSince time.Time,
	changesUntil time.Time,
) ([]*Set, error) {
	slogctx.Info(ctx, "getting sets")

	const query = selectSets + `
		WHERE (owner_subject = @subject OR shared)
			AND last_changed_at >= @since AND last_changed_at <= @until
		ORDER BY last_changed_at DESC`

	rows, err := db.Query(ctx, query, pgx.NamedArgs{
		"subject": user.Subject,
		"email":   user.Email,
		"since":   changesSince,
		"until":   changesUntil,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query database: %w", err)
	}

	sets, err := scanSets(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan set db row: %w", err)
	}

	if err := fillIn(ctx, db, sets, user); err != nil {
		return nil, fmt.Errorf("failed to read the entries and shares of the sets: %w", err)
	}

	// The headstones are added after the entries are read, so that nothing is
	// read for them: they say the set is gone, and nothing about what is in it.
	unshared, err := listUnshared(ctx, db, user, changesSince, changesUntil)
	if err != nil {
		return nil, err
	}
	if len(unshared) == 0 {
		return sets, nil
	}
	sets = append(sets, unshared...)
	slices.SortStableFunc(sets, func(a, b *Set) int {
		return b.LastChangedAt.Compare(a.LastChangedAt)
	})
	return sets, nil
}

// listUnshared answers the sets the caller's address was taken off within the
// window, each as a headstone: the set as the listing answers one that was
// deleted, gone from the moment the address was taken off.
//
// To the person who was taken off, that is what happened — the set is gone —
// and saying it the same way means a client that already knows what to do with
// a deleted set knows what to do with this one. Without it the set would simply
// stop turning up, and a device holding a copy would go on holding it for good,
// since nothing would ever say otherwise.
//
// Only the id and the moment are real. The title and what is in it are left
// empty: the caller is no longer somebody the set is shared with, and what it
// has been called since is none of their business. A device dropping a set it
// is told is gone has no use for what is in it anyway.
//
// A set the caller owns, or is on again, is not a headstone: re-sharing forgets
// the note, and an owner is never on the list of their own sets in the first
// place, but either would put the set in the answer twice.
func listUnshared(
	ctx context.Context,
	db *pgxpool.Conn,
	user User,
	changesSince time.Time,
	changesUntil time.Time,
) ([]*Set, error) {
	const query = `
		SELECT u.set_id, s.owner_subject, '', '', u.unshared_at, u.unshared_at
		FROM set_unshares AS u
		JOIN sets AS s ON s.id = u.set_id
		WHERE u.email = @email
			AND s.owner_subject <> @subject
			AND NOT EXISTS (
				SELECT 1 FROM set_shares AS sh
				WHERE sh.set_id = u.set_id AND sh.email = @email)
			AND u.unshared_at >= @since AND u.unshared_at <= @until`

	rows, err := db.Query(ctx, query, pgx.NamedArgs{
		"subject": user.Subject,
		"email":   user.Email,
		"since":   changesSince,
		"until":   changesUntil,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query the sets the caller was taken off: %w", err)
	}

	unshared, err := scanSets(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan the sets the caller was taken off: %w", err)
	}
	return unshared, nil
}

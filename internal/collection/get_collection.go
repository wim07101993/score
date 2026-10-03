package collection

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

func Get(ctx context.Context, db *pgxpool.Conn, collectionId string, user User) (*Collection, error) {
	slogctx.Info(ctx, "getting collection", slog.String("collectionId", collectionId))

	const query = selectCollections + `
		WHERE id = @id
			AND (owner_subject = @subject OR shared)
			AND deletedAt IS NULL`

	rows, err := db.Query(ctx, query, pgx.NamedArgs{
		"id":      collectionId,
		"subject": user.Subject,
		"email":   user.Email,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query database: %w", err)
	}

	collections, err := scanCollections(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan collection db row: %w", err)
	}
	if len(collections) == 0 {
		return nil, ErrCollectionNotFound
	}

	if err := fillIn(ctx, db, collections, user); err != nil {
		return nil, fmt.Errorf("failed to read the entries and shares of the collection: %w", err)
	}
	return collections[0], nil
}

func List(
	ctx context.Context,
	db *pgxpool.Conn,
	user User,
	changesSince time.Time,
	changesUntil time.Time,
) ([]*Collection, error) {
	slogctx.Info(ctx, "getting collections")

	const query = selectCollections + `
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

	collections, err := scanCollections(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan collection db row: %w", err)
	}

	if err := fillIn(ctx, db, collections, user); err != nil {
		return nil, fmt.Errorf("failed to read the entries and shares of the collections: %w", err)
	}

	// The headstones are added after the entries are read, so that nothing is
	// read for them: they say the collection is gone, and nothing about what is
	// in it.
	unshared, err := listUnshared(ctx, db, user, changesSince, changesUntil)
	if err != nil {
		return nil, err
	}
	if len(unshared) == 0 {
		return collections, nil
	}
	collections = append(collections, unshared...)
	slices.SortStableFunc(collections, func(a, b *Collection) int {
		return b.LastChangedAt.Compare(a.LastChangedAt)
	})
	return collections, nil
}

// listUnshared answers the collections the caller's address was taken off
// within the window, each as a headstone: the collection as the listing answers
// one that was deleted, gone from the moment the address was taken off.
//
// To the person who was taken off, that is what happened — the collection is
// gone — and saying it the same way means a client that already knows what to
// do with a deleted collection knows what to do with this one. Without it the
// collection would simply stop turning up, and a device holding a copy would go
// on holding it for good, since nothing would ever say otherwise.
//
// Only the id and the moment are real. The title and what is in it are left
// empty: the caller is no longer somebody the collection is shared with, and
// what it has been called since is none of their business. A device dropping a
// collection it is told is gone has no use for what is in it anyway.
//
// A collection the caller owns, or is on again, is not a headstone: re-sharing
// forgets the note, and an owner is never on the list of their own collections
// in the first place, but either would put the collection in the answer twice.
func listUnshared(
	ctx context.Context,
	db *pgxpool.Conn,
	user User,
	changesSince time.Time,
	changesUntil time.Time,
) ([]*Collection, error) {
	const query = `
		SELECT u.collection_id, c.owner_subject, '', '', u.unshared_at, u.unshared_at
		FROM collection_unshares AS u
		JOIN collections AS c ON c.id = u.collection_id
		WHERE u.email = @email
			AND c.owner_subject <> @subject
			AND NOT EXISTS (
				SELECT 1 FROM collection_shares AS sh
				WHERE sh.collection_id = u.collection_id AND sh.email = @email)
			AND u.unshared_at >= @since AND u.unshared_at <= @until`

	rows, err := db.Query(ctx, query, pgx.NamedArgs{
		"subject": user.Subject,
		"email":   user.Email,
		"since":   changesSince,
		"until":   changesUntil,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query the collections the caller was taken off: %w", err)
	}

	unshared, err := scanCollections(rows, user)
	if err != nil {
		return nil, fmt.Errorf("failed to scan the collections the caller was taken off: %w", err)
	}
	return unshared, nil
}

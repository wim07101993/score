package collection

import (
	"context"
	"fmt"
	"log/slog"
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
	return collections, nil
}

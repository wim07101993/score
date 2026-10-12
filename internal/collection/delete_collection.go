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

func Delete(ctx context.Context, db *pgxpool.Conn, collectionId string, user User) error {
	slogctx.Info(ctx, "deleting collection", slog.String("collectionId", collectionId))

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const moveQuery = `
		INSERT INTO deleted_collections (id, owner_subject, shared_with, deleted_at)
		SELECT id, owner_subject,
		       ARRAY(SELECT email FROM collection_shares WHERE collection_id = @id
		             UNION
		             SELECT email FROM collection_unshares WHERE collection_id = @id),
		       @now
		FROM collections
		WHERE id = @id AND owner_subject = @owner_subject
		ON CONFLICT (id) DO UPDATE SET
			owner_subject = EXCLUDED.owner_subject,
			shared_with = EXCLUDED.shared_with,
			deleted_at = EXCLUDED.deleted_at`

	args := pgx.NamedArgs{
		"id":            collectionId,
		"owner_subject": user.Subject,
		"now":           time.Now().UTC(),
	}
	tag, err := tx.Exec(ctx, moveQuery, args)
	if err != nil {
		return fmt.Errorf("failed to delete the collection: %w", err)
	}
	if tag.RowsAffected() == 0 {
		// Either it is not there, already gone, or not theirs. Telling the
		// three apart would say more about other people's collections than it
		// should.
		return ErrCollectionNotFound
	}

	if _, err := tx.Exec(ctx, `DELETE FROM collections WHERE id = @id`, args); err != nil {
		return fmt.Errorf("failed to delete the collection: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the deletion: %w", err)
	}
	return nil
}

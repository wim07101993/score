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

	const query = `
		UPDATE collections
		SET deletedAt = @deletedAt, lastChangedAt = @lastChangedAt
		WHERE id = @id AND owner_subject = @owner_subject AND deletedAt IS NULL`

	now := time.Now().UTC()
	tag, err := db.Exec(ctx, query, pgx.NamedArgs{
		"id":            collectionId,
		"owner_subject": user.Subject,
		"deletedAt":     now,
		"lastChangedAt": now,
	})
	if err != nil {
		return fmt.Errorf("failed to delete the collection: %w", err)
	}
	if tag.RowsAffected() == 0 {
		// Either it is not there, already gone, or not theirs. Telling the
		// three apart would say more about other people's collections than it
		// should.
		return ErrCollectionNotFound
	}
	return nil
}

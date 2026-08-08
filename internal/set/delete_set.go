package set

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

func Delete(ctx context.Context, db *pgxpool.Conn, setId string, user User) error {
	slogctx.Info(ctx, "deleting set", slog.String("setId", setId))

	const query = `
		UPDATE sets
		SET deletedAt = @deletedAt, lastChangedAt = @lastChangedAt
		WHERE id = @id AND owner_subject = @owner_subject AND deletedAt IS NULL`

	now := time.Now().UTC()
	tag, err := db.Exec(ctx, query, pgx.NamedArgs{
		"id":            setId,
		"owner_subject": user.Subject,
		"deletedAt":     now,
		"lastChangedAt": now,
	})
	if err != nil {
		return fmt.Errorf("failed to delete the set: %w", err)
	}
	if tag.RowsAffected() == 0 {
		// Either it is not there, already gone, or not theirs. Telling the
		// three apart would say more about other people's sets than it should.
		return ErrSetNotFound
	}
	return nil
}

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

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const moveQuery = `
		INSERT INTO deleted_sets (id, owner_subject, shared_with, deleted_at)
		SELECT id, owner_subject,
		       ARRAY(SELECT email FROM set_shares WHERE set_id = @id
		             UNION
		             SELECT email FROM set_unshares WHERE set_id = @id),
		       @now
		FROM sets
		WHERE id = @id AND owner_subject = @owner_subject
		ON CONFLICT (id) DO UPDATE SET
			owner_subject = EXCLUDED.owner_subject,
			shared_with = EXCLUDED.shared_with,
			deleted_at = EXCLUDED.deleted_at`

	args := pgx.NamedArgs{
		"id":            setId,
		"owner_subject": user.Subject,
		"now":           time.Now().UTC(),
	}
	tag, err := tx.Exec(ctx, moveQuery, args)
	if err != nil {
		return fmt.Errorf("failed to delete the set: %w", err)
	}
	if tag.RowsAffected() == 0 {
		// Either it is not there, already gone, or not theirs. Telling the
		// three apart would say more about other people's sets than it
		// should.
		return ErrSetNotFound
	}

	if _, err := tx.Exec(ctx, `DELETE FROM sets WHERE id = @id`, args); err != nil {
		return fmt.Errorf("failed to delete the set: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the deletion: %w", err)
	}
	return nil
}

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

func Get(ctx context.Context, db *pgxpool.Conn, setId string, user User) (*Set, error) {
	slogctx.Info(ctx, "getting set", slog.String("setId", setId))

	const query = selectSets + `
		WHERE s.id = @id
			AND (s.owner_subject = @subject OR sh.email IS NOT NULL)
			AND s.deletedAt IS NULL`

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
		WHERE (s.owner_subject = @subject OR sh.email IS NOT NULL)
			AND s.lastChangedAt >= @since AND s.lastChangedAt <= @until
		ORDER BY s.lastChangedAt DESC`

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
	return sets, nil
}

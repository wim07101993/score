package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"log/slog"
)

func (db *ScoresDb) RemoveScore(ctx context.Context, id string) error {
	db.logger.Info("removing score document", slog.String("id", id))

	const query = `DELETE FROM scores WHERE id = $id`

	db.logger.Debug("Executing query", slog.String("query", query))
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{"id": id})
	return err
}

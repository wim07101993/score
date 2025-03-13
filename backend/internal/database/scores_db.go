package database

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
)

type ScoresDbFactory func(ctx context.Context) (*ScoresDb, error)

type ScoresDb struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewScoresDb(logger *slog.Logger, conn *pgxpool.Conn) *ScoresDb {
	return &ScoresDb{
		logger: logger,
		conn:   conn,
	}
}

func (db *ScoresDb) ReleaseConnection() {
	db.conn.Release()
}

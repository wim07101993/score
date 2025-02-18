package database

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
)

type ScoresDBFactory func(ctx context.Context) (*ScoresDB, error)

type ScoresDB struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewScoresDB(logger *slog.Logger, conn *pgxpool.Conn) *ScoresDB {
	return &ScoresDB{
		logger: logger,
		conn:   conn,
	}
}

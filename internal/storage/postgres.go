package storage

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DatabaseConfig struct {
	ConnectionString string
}

type DBConnProvider interface {
	Provide(ctx context.Context) (*pgxpool.Conn, error)
}

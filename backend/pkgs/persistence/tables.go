package persistence

import (
	"github.com/jmoiron/sqlx"
	"log/slog"
)

type SqlTables struct {
	logger *slog.Logger
	db     sqlx.DB
}

func NewSqlTables(logger *slog.Logger, db sqlx.DB) *SqlTables {
	return &SqlTables{
		logger: logger,
		db:     db,
	}
}

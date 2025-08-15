package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"score/config"
	"score/internal/auth"
	"score/internal/score"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var cfg config.Config
var pgPool *pgxpool.Pool

func main() {
	if err := cfg.FromFile(); err != nil {
		log.Fatalf("failed to read config file: %v", err)
	}
	if err := cfg.FromEnv(); err != nil {
		log.Fatalf("failed to read config from env: %v", err)
	}
	logger.Info("validating config")
	if err := cfg.Validate(); err != nil {
		log.Fatalf("config invalid: %v", err)
	}
	logger.Debug("starting application with config", slog.Any("config", cfg))

	runMigrations()

	var err error
	pgPool, err = pgxpool.New(context.Background(), cfg.DbConnectionString)
	if err != nil {
		log.Fatalf("failed to obtain db-connection pool: %v", err)
	}

	serveHttp()
}

func runMigrations() {
	logger.Info("running migrations")
	db, err := sql.Open("postgres", cfg.DbConnectionString)
	if err != nil {
		log.Fatalf("failed to open database for migrations: %v", err)
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://db/migrations",
		"postgres",
		driver)
	if err != nil {
		log.Fatalf("failed to create migration runner: %v", err)
	}

	if err := m.Up(); err != nil {
		if errors.Is(err, migrate.ErrNoChange) {
			logger.Info("migrations already up-to-date")
			return
		}

		log.Fatalf("failed to run migrations: %v", err)
	}

	logger.Info("migrated successfully")
}

func serveHttp() {
	logger.Info("starting http server")

	authMiddleware := auth.NewMiddleware(cfg.TokenIntrospectionUrl, cfg.TokenIntrospectionClientId, cfg.TokenIntrospectionClientSecret)

	scoreServ := score.NewHttpServer(logger, createScoresDb, authMiddleware)
	scoreServ.RegisterRoutes()

	addr := fmt.Sprintf(":%d", cfg.HttpServerPort)
	logger.Info("start listening for http requests", slog.String("addr", addr))
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err))
	}
}

func createScoresDb(ctx context.Context) (*score.Database, error) {
	pgConn, err := pgPool.Acquire(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create database connection")
	}
	return score.NewDatabase(logger, pgConn), nil
}

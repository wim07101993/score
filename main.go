package main

import (
	"context"
	"database/sql"
	"flag"
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
	_ "golang.org/x/crypto/x509roots/fallback" // CA bundle for FROM Scratch
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var cfg = &config.Config{}
var pgPool *pgxpool.Pool

var configPath string

func main() {
	flag.StringVar(&configPath, "config", "", "Specifies the file from which config should be read. If none is provided, only environment variables are read.")
	flag.Parse()

	fromEnv, err := config.FromEnv()
	if err != nil {
		log.Fatalf("failed to read config from env: %v", err)
	}
	logger.Debug("env config", slog.Any("config", fromEnv.Redacted()))
	cfg.CopyFrom(fromEnv)

	if configPath != "" {
		fromFile, err := config.FromFile(configPath)
		if err != nil {
			log.Fatalf("failed to get config from file: %v", err)
		}
		logger.Debug("file config", slog.Any("config", fromFile.Redacted()))
		cfg.CopyFrom(fromFile)
	}

	logger.Info("validating config")
	if err := cfg.Validate(); err != nil {
		log.Fatalf("config invalid: %v", err)
	}

	logger.Info("starting application with config", slog.Any("config", cfg.Redacted()))

	runMigrations()

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

	authMiddleware := auth.NewMiddleware(
		cfg.TokenIntrospectionUrl,
		cfg.UserInfoUrl,
		cfg.TokenIntrospectionClientId,
		cfg.TokenIntrospectionClientSecret,
		cfg.RolesKey)

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

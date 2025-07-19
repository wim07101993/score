package main

import (
	"context"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
	"log/slog"
	"net/http"
	"os"
	"score/backend/internal/auth"
	"score/backend/internal/score"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var cfg Config
var pgPool *pgxpool.Pool

func main() {
	if err := cfg.FromFile(); err != nil {
		panic(err)
	}
	if err := cfg.FromEnv(); err != nil {
		panic(err)
	}
	if err := cfg.Validate(); err != nil {
		panic(err)
	}
	logger.Debug("starting application with config", slog.Any("config", cfg))

	var err error
	pgPool, err = pgxpool.New(context.Background(), cfg.DbConnectionString)
	if err != nil {
		panic(err)
	}

	serveHttp()
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

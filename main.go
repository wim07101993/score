package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"score/config"
	"score/internal/bootstrap"
	"score/internal/oidc"
	"score/internal/storage"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/pkg/errors"
	slogctx "github.com/veqryn/slog-context"
	_ "golang.org/x/crypto/x509roots/fallback" // CA bundle for FROM Scratch
)

// The API is described in api/openapi-spec.yaml; the server that serves it is
// generated from that document into internal/api.
//go:generate go tool ogen --config ogen.yml --target internal/api --package api --clean api/openapi-spec.yaml

var cfg = &config.Config{}
var dc *bootstrap.DependencyContainer

var configPath string

func main() {
	ctx := context.Background()
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	flag.StringVar(&configPath, "config", "", "Specifies the file from which config should be read. If none is provided, only environment variables are read.")
	flag.Parse()

	fromEnv, err := config.FromEnv()
	if err != nil {
		log.Fatalf("failed to read config from env: %v", err)
	}
	slog.Debug("env config", slog.Any("config", fromEnv.Redacted()))
	cfg.CopyFrom(fromEnv)

	if configPath != "" {
		fromFile, err := config.FromFile(configPath)
		if err != nil {
			log.Fatalf("failed to get config from file: %v", err)
		}
		slog.Debug("file config", slog.Any("config", fromFile.Redacted()))
		cfg.CopyFrom(fromFile)
	}

	slog.Info("validating config")
	if err := cfg.Validate(); err != nil {
		log.Fatalf("config invalid: %v", err)
	}

	dc = bootstrap.DefaultDependencyContainer(
		bootstrap.NewSingleton[oidc.ClientConfig](cfg.OidcClientConfig()),
		bootstrap.NewSingleton[storage.DatabaseConfig](cfg.DatabaseConfig()),
	)

	logger, err := dc.Logger.Provide(ctx)
	if err != nil {
		log.Fatalf("failed to create default logger: %v", err)
	}

	slog.SetDefault(logger)
	slog.Info("starting application with config", slog.Any("config", cfg.Redacted()))

	if err := runMigrations(ctx); err != nil {
		slog.Error("failed to run migrations", slogctx.Err(err))
	}
	if err := serveHttp(ctx); err != nil {
		slog.Error("failed to run http server", slogctx.Err(err))
	}
}

func runMigrations(ctx context.Context) (err error) {
	slogctx.Info(ctx, "running migrations")

	var m *bootstrap.DependencyWithCleanup[*migrate.Migrate]
	m, err = dc.Migrate.Provide(ctx)
	if err != nil {
		return fmt.Errorf("failed to start database migration: %w", err)
	}
	defer func() {
		err = m.Cleanup()
	}()

	if err = m.Dependency.Up(); err != nil {
		if errors.Is(err, migrate.ErrNoChange) {
			slogctx.Info(ctx, "migrations already up-to-date")
			return nil
		}
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	slogctx.Info(ctx, "migrated successfully")
	return err
}

func serveHttp(ctx context.Context) (err error) {
	slogctx.Info(ctx, "starting http server")

	var server http.Handler
	server, err = dc.HttpHandler.Provide(ctx)
	if err != nil {
		return fmt.Errorf("failed to create http handler: %w", err)
	}

	addr := fmt.Sprintf(":%d", cfg.HttpServerPort)
	slogctx.Info(ctx, "start listening for http requests", slog.String("addr", addr))

	err = http.ListenAndServe(addr, server)
	if err != nil {
		return fmt.Errorf("failed to listen for requests: %w", err)
	}
	return nil
}

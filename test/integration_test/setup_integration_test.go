//go:build integration

package integration_test

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"testing"

	"score/test/integration_test/helpers"

	"github.com/golang-migrate/migrate/v4"
	slogctx "github.com/veqryn/slog-context"
)

var ApplicationLogs = &strings.Builder{}

func TestMain(m *testing.M) {
	os.Exit(runTests(m))
}

func runTests(m *testing.M) int {
	ctx := context.Background()

	ApplicationLogs.WriteString("----------------------------------------------------------------------------")
	ApplicationLogs.WriteString("------------------------------APPLICATION LOGS------------------------------")
	ApplicationLogs.WriteString("----------------------------------------------------------------------------")
	slog.SetDefault(slog.New(slog.NewTextHandler(ApplicationLogs, nil)))
	defer func() {
		ApplicationLogs.WriteString("----------------------------------------------------------------------------")
		ApplicationLogs.WriteString("----------------------------END APPLICATION LOGS----------------------------")
		ApplicationLogs.WriteString("----------------------------------------------------------------------------")
		fmt.Println(ApplicationLogs)
	}()

	databaseUrl, stop, err := helpers.StartEmbeddedPostgres()
	if err != nil {
		slogctx.Error(ctx, "failed to start database", slogctx.Err(err))
		return 1
	}
	defer stop()

	harness = helpers.NewHarness(databaseUrl)

	migrator, err := harness.Migrate.Provide(ctx)
	if err != nil {
		slogctx.Error(ctx, "failed to create database migrator", slogctx.Err(err))
		return 1
	}
	defer func() { err = errors.Join(err, migrator.Cleanup()) }()

	if err := migrator.Dependency.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		slogctx.Error(ctx, "failed to migrate database", slogctx.Err(err))
		return 1
	}

	return m.Run()
}

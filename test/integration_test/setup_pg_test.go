//go:build integration

package integration_test

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"testing"

	"score/test/integration_test/helpers"

	"github.com/jackc/pgx/v5/pgxpool"
)

// LogEnvVar turns the API's own logging back on. The served handler writes to
// slog.Default(), which a test run silences: a green run has no use for a log
// line per request, and a red one is diagnosed from the failure body. Set it
// when the log is what you are actually after.
const LogEnvVar = "SCORE_TEST_LOG"

func TestMain(m *testing.M) {
	os.Exit(runTests(m))
}

func runTests(m *testing.M) int {
	ctx := context.Background()

	if os.Getenv(LogEnvVar) == "" {
		slog.SetDefault(slog.New(slog.NewTextHandler(io.Discard, nil)))
	}

	databaseUrl, stop, err := helpers.PostgresUrl(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to start a database: %v\n", err)
		return 1
	}
	defer stop()

	pool, err := pgxpool.New(ctx, databaseUrl)
	if err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to connect to the database: %v\n", err)
		return 1
	}
	defer pool.Close()

	harness = helpers.NewHarness(databaseUrl, pool)

	// The application migrates itself on start-up, so the tests run against a
	// fully migrated database too.
	if err := harness.MigrateUp(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to migrate the database: %v\n", err)
		return 1
	}

	return m.Run()
}

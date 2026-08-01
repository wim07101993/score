//go:build integration

package integration_test

import (
	"context"
	"fmt"
	"os"
	"testing"

	"score/test/integration_test/helpers"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestMain(m *testing.M) {
	os.Exit(runTests(m))
}

func runTests(m *testing.M) int {
	ctx := context.Background()

	databaseUrl, stop, err := helpers.PostgresUrl(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to start a database: %v\n", err)
		return 1
	}
	defer stop()

	// The application migrates itself on start-up, so the tests run against a
	// fully migrated database too.
	if err := helpers.MigrateUp(databaseUrl); err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to migrate the database: %v\n", err)
		return 1
	}

	pool, err := pgxpool.New(ctx, databaseUrl)
	if err != nil {
		fmt.Fprintf(os.Stderr, "setup: failed to connect to the database: %v\n", err)
		return 1
	}
	defer pool.Close()

	harness.DB = pool
	harness.DatabaseUrl = databaseUrl

	return m.Run()
}

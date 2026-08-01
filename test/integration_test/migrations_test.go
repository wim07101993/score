//go:build integration

package integration_test

import (
	"context"
	"testing"

	"score/test/integration_test/helpers"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMigrationsCanBeRolledBackAndReapplied exercises the down migrations,
// which nothing else ever runs. It works on a database of its own so a broken
// rollback cannot take the rest of the suite with it.
func TestMigrationsCanBeRolledBackAndReapplied(t *testing.T) {
	const databaseName = "score_migration_test"

	ctx := context.Background()
	pool := harness.EnsureDatabase(t)

	_, err := pool.Exec(ctx, "DROP DATABASE IF EXISTS "+databaseName)
	require.NoError(t, err, "failed to clean up a previous migration test database")
	_, err = pool.Exec(ctx, "CREATE DATABASE "+databaseName)
	require.NoError(t, err, "failed to create the migration test database")
	t.Cleanup(func() {
		_, _ = pool.Exec(context.Background(), "DROP DATABASE IF EXISTS "+databaseName)
	})

	databaseUrl, err := helpers.WithDatabaseName(harness.DatabaseUrl, databaseName)
	require.NoError(t, err)

	migrator, db, err := helpers.Migrator(databaseUrl)
	require.NoError(t, err)
	defer func() { _ = db.Close() }()

	require.NoError(t, migrator.Up(), "failed to apply the migrations")
	assert.NoError(t, migrator.Down(), "failed to roll every migration back")
	assert.NoError(t, migrator.Up(), "failed to re-apply the migrations after a rollback")
}

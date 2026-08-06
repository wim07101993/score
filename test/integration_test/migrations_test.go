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

	migrator, err := helpers.Migrator(ctx, databaseUrl)
	require.NoError(t, err)
	defer func() { _ = migrator.Cleanup() }()

	require.NoError(t, migrator.Dependency.Up(), "failed to apply the migrations")
	assert.NoError(t, migrator.Dependency.Down(), "failed to roll every migration back")
	assert.NoError(t, migrator.Dependency.Up(), "failed to re-apply the migrations after a rollback")
}

// TestTheMigrationRunnerCleansUpAfterItself guards the shutdown half of the
// migration dependency. main reports whatever Cleanup returns, so a cleanup
// that closes the same handle twice makes every successful start-up look like a
// failed one.
func TestTheMigrationRunnerCleansUpAfterItself(t *testing.T) {
	ctx := context.Background()

	migrator, err := helpers.Migrator(ctx, harness.DatabaseUrl)
	require.NoError(t, err)

	assert.NoError(t, migrator.Cleanup(), "cleaning up after the migrations should not report a failure")
}

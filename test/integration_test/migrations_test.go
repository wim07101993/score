//go:build integration

package integration_test

import (
	"testing"

	"score/test/integration_test/helpers"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMigrationsCanBeRolledBackAndReapplied exercises the down migrations,
// which nothing else ever runs. It works on a database of its own so a broken
// rollback cannot take the rest of the suite with it.
func TestMigrationsCanBeRolledBackAndReapplied(t *testing.T) {
	t.Parallel()

	databaseUrl, stop, err := helpers.StartEmbeddedPostgres()
	require.NoError(t, err)
	defer stop()

	harness := helpers.NewHarness(databaseUrl)

	migrator := helpers.Ensure(t, harness.Migrate, "migrate")
	defer func() {
		require.NoError(t, migrator.Cleanup())
	}()

	require.NoError(t, migrator.Dependency.Up(), "failed to apply the migrations")
	assert.NoError(t, migrator.Dependency.Down(), "failed to roll every migration back")
	assert.NoError(t, migrator.Dependency.Up(), "failed to re-apply the migrations after a rollback")
}

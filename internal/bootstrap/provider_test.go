package bootstrap

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// counted returns a provider function that reports how often it was called, so
// a test can say whether a dependency was built once or built again.
func counted(value int) (ProviderFunc[int], *int) {
	calls := 0
	return func(ctx context.Context) (int, error) {
		calls++
		return value, nil
	}, &calls
}

// TestALazySingletonIsBuiltOnce is what separates a lazy singleton from a
// factory. Everything expensive in the container is one — a connection pool, an
// http handler — and building those again per call leaks whatever the previous
// one held.
func TestALazySingletonIsBuiltOnce(t *testing.T) {
	ctx := context.Background()
	factory, calls := counted(42)

	singleton := NewLazySingleton(factory)

	assert.Zero(t, *calls, "a lazy singleton should not build anything before it is asked to")

	for range 3 {
		value, err := singleton.Provide(ctx)
		require.NoError(t, err)
		assert.Equal(t, 42, value)
	}

	assert.Equal(t, 1, *calls, "a lazy singleton should build its value once and reuse it")
}

// TestALazySingletonRetriesAfterAFailure keeps a transient failure — a database
// that is not up yet — from poisoning the dependency for the rest of the
// process.
func TestALazySingletonRetriesAfterAFailure(t *testing.T) {
	ctx := context.Background()
	failure := errors.New("not ready")

	calls := 0
	singleton := NewLazySingleton(func(ctx context.Context) (int, error) {
		calls++
		if calls == 1 {
			return 0, failure
		}
		return 42, nil
	})

	_, err := singleton.Provide(ctx)
	require.ErrorIs(t, err, failure)

	value, err := singleton.Provide(ctx)
	require.NoError(t, err)
	assert.Equal(t, 42, value)
	assert.Equal(t, 2, calls, "a failed build should not be remembered as a built value")
}

// TestAFactoryIsBuiltEveryTime is the other half of the contract: a database
// connection is handed out per request and must not be shared between them.
func TestAFactoryIsBuiltEveryTime(t *testing.T) {
	ctx := context.Background()
	provider, calls := counted(42)

	factory := NewFactory(provider)

	for range 3 {
		value, err := factory.Provide(ctx)
		require.NoError(t, err)
		assert.Equal(t, 42, value)
	}

	assert.Equal(t, 3, *calls, "a factory should build a new value for every caller")
}

func TestASingletonAlwaysProvidesTheValueItWasGiven(t *testing.T) {
	ctx := context.Background()

	value, err := NewSingleton(42).Provide(ctx)
	require.NoError(t, err)
	assert.Equal(t, 42, value)
}

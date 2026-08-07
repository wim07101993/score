// Package helpers holds the test harness for the score integration tests.
//
// The harness is the application's own dependency container with the parts of
// the world the tests own swapped in: their database pool, a fake identity
// provider, and migrations found from the test package. On top of it sit the
// few things only a test needs — the http server the API is reached through and
// a client that talks to it.
//
// Every dependency is built lazily and reused afterwards, so a test only pays
// for what it actually touches.
package helpers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"score/internal/bootstrap"
	"score/internal/server"
	"score/internal/storage"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
)

type Harness struct {
	*bootstrap.DependencyContainer

	DatabaseUrl string

	HttpClient       bootstrap.Provider[*http.Client]
	IdentityProvider bootstrap.Provider[*IdentityProvider]
	TestServer       bootstrap.Provider[*httptest.Server]
	RawClient        bootstrap.Provider[*RawClient]
}

func NewHarness(databaseUrl string, pool *pgxpool.Pool) *Harness {
	h := &Harness{DatabaseUrl: databaseUrl}

	h.HttpClient = bootstrap.NewLazySingleton(h.NewHttpClient)
	h.IdentityProvider = bootstrap.NewLazySingleton(h.NewIdentityProvider)
	h.TestServer = bootstrap.NewLazySingleton(h.NewTestServer)
	h.RawClient = bootstrap.NewLazySingleton(h.NewRawClient)

	h.DependencyContainer = bootstrap.DefaultDependencyContainer(
		bootstrap.NewLazySingleton(h.NewOidcClientConfig),
		bootstrap.NewSingleton(storage.DatabaseConfig{ConnectionString: databaseUrl}),
	)

	h.PgxPool = bootstrap.NewSingleton(pool)
	h.MigrationsSource = bootstrap.NewSingleton(MigrationsSource)

	server.FullErrorInResponse.Store(true)

	return h
}

func ensure[T any](t *testing.T, provider bootstrap.Provider[T], what string) T {
	t.Helper()

	value, err := provider.Provide(context.Background())
	require.NoErrorf(t, err, "failed to build the %s", what)
	require.NotNilf(t, value, "the %s was built as nil", what)
	return value
}

func (h *Harness) NewHttpClient(ctx context.Context) (*http.Client, error) {
	return &http.Client{
		Timeout: 30 * time.Second,
		// Redirects would hide the status code the API actually returned.
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}, nil
}

func (h *Harness) NewTestServer(ctx context.Context) (*httptest.Server, error) {
	handler, err := h.HttpHandler.Provide(ctx)
	if err != nil {
		return nil, err
	}

	return httptest.NewServer(handler), nil
}

func (h *Harness) EnsureApiServer(t *testing.T) *httptest.Server {
	t.Helper()
	return ensure(t, h.TestServer, "api server")
}

func (h *Harness) EnsureDatabase(t *testing.T) *pgxpool.Pool {
	t.Helper()
	return ensure(t, h.PgxPool, "database pool")
}

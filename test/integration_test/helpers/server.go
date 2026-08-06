package helpers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"score/internal/bootstrap"
	"score/internal/oidc"
	"score/internal/server"
	"score/internal/storage"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
)

// EnsureApiServer starts the real score API in front of the harness database
// and the fake identity provider.
func (h *Harness) EnsureApiServer(t *testing.T) *httptest.Server {
	t.Helper()
	h.apiServer.mutex.Lock()
	defer h.apiServer.mutex.Unlock()

	if h.apiServer.value == nil {
		// Not closed on test cleanup: the harness builds it once and every
		// later test reuses it, so it lives as long as the test binary.
		h.apiServer.value = httptest.NewServer(h.EnsureApiHandler(t))
	}
	return h.apiServer.value
}

// EnsureDependencies builds the same dependency graph main builds, with the
// harness standing in for the parts of the world the tests own: its database
// pool, its fake identity provider, and migrations found from the test package
// rather than from the repository root.
//
// Tests that need to reach further into the graph — to take a single dependency
// apart, or to swap one for a double — go through here.
func (h *Harness) EnsureDependencies(t *testing.T) *bootstrap.DependencyContainer {
	t.Helper()
	h.dependencies.mutex.Lock()
	defer h.dependencies.mutex.Unlock()

	if h.dependencies.value == nil {
		idp := h.EnsureIdentityProvider(t)

		dc := bootstrap.DefaultDependencyContainer(
			bootstrap.NewSingleton[oidc.ClientConfig](oidc.ClientConfig{
				IntrospectionUrl: idp.IntrospectionUrl(),
				UserInfoUrl:      idp.UserInfoUrl(),
				ClientId:         IdpClientId,
				ClientSecret:     IdpClientSecret,
				RolesKey:         RolesKey,
			}),
			bootstrap.NewSingleton[storage.DatabaseConfig](storage.DatabaseConfig{
				ConnectionString: h.DatabaseUrl,
			}),
		)

		// The harness already owns a pool, opened against the database it set
		// up; the container is given that one rather than opening a second.
		dc.PgxPool = bootstrap.NewSingleton[*pgxpool.Pool](h.EnsureDatabase(t))
		dc.MigrationsSource = bootstrap.NewSingleton(MigrationsSource)

		h.dependencies.value = dc
	}
	return h.dependencies.value
}

// EnsureApiHandler builds the real API, the same way main does.
func (h *Harness) EnsureApiHandler(t *testing.T) http.Handler {
	t.Helper()
	h.apiHandler.mutex.Lock()
	defer h.apiHandler.mutex.Unlock()

	if h.apiHandler.value == nil {
		// A red integration run should say what actually went wrong rather
		// than "an unexpected error happened". See FullErrorInResponse.
		server.FullErrorInResponse.Store(true)

		// Not t.Context(): the handler is built once and served to every later
		// test, so it may not be tied to the lifetime of whichever test
		// happened to ask for it first.
		apiHandler, err := h.EnsureDependencies(t).HttpHandler.Provide(context.Background())
		require.NoError(t, err, "failed to build the api server")

		h.apiHandler.value = apiHandler
	}
	return h.apiHandler.value
}

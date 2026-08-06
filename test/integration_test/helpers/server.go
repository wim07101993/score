package helpers

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"score/internal/auth"
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

// EnsureBootstrapper builds the same dependency graph main builds, with the
// harness standing in for the parts of the world the tests own: its database
// pool, its fake identity provider, and a logger that goes nowhere.
//
// Tests that need to reach further into the graph — to take the security
// handler apart, or to swap one dependency for a double — go through here.
func (h *Harness) EnsureBootstrapper(t *testing.T) *bootstrap.DependencyContainer {
	t.Helper()
	h.bootstrapper.mutex.Lock()
	defer h.bootstrapper.mutex.Unlock()

	if h.bootstrapper.value == nil {
		idp := h.EnsureIdentityProvider(t)

		b := bootstrap.DefaultDependencyContainer(
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
		// up; the bootstrapper is given that one rather than opening a second.
		b.PgxPool = bootstrap.NewSingleton[*pgxpool.Pool](h.EnsureDatabase(t))
		b.Logger = bootstrap.NewSingleton[*slog.Logger](
			slog.New(slog.NewTextHandler(io.Discard, nil)))

		h.bootstrapper.value = b
	}
	return h.bootstrapper.value
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

		apiHandler, err := h.EnsureBootstrapper(t).HttpHandler.Provide(t.Context())
		require.NoError(t, err, "failed to build the api server")

		h.apiHandler.value = apiHandler
	}
	return h.apiHandler.value
}

func (h *Harness) EnsureSecurityHandler(t *testing.T) *auth.SecurityHandler {
	t.Helper()
	h.securityHandler.mutex.Lock()
	defer h.securityHandler.mutex.Unlock()

	if h.securityHandler.value == nil {
		securityHandler, err := h.EnsureBootstrapper(t).AuthSecurityHandler.Provide(t.Context())
		require.NoError(t, err, "failed to build the security handler")
		require.NotNil(t, securityHandler)

		h.securityHandler.value = securityHandler
	}
	return h.securityHandler.value
}

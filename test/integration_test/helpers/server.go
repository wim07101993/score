package helpers

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"score/internal/auth"
	"score/internal/oidc"
	"score/internal/score"
	"score/internal/server"

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

// EnsureApiHandler builds the real API, the same way main does.
func (h *Harness) EnsureApiHandler(t *testing.T) http.Handler {
	t.Helper()
	h.apiHandler.mutex.Lock()
	defer h.apiHandler.mutex.Unlock()

	if h.apiHandler.value == nil {
		pool := h.EnsureDatabase(t)
		logger := slog.New(slog.NewTextHandler(io.Discard, nil))

		apiHandler, err := server.New(func(ctx context.Context) (*score.Database, error) {
			conn, err := pool.Acquire(ctx)
			if err != nil {
				return nil, err
			}
			return score.NewDatabase(conn), nil
		}, h.EnsureSecurityHandler(t))
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
		idp := h.EnsureIdentityProvider(t)
		h.securityHandler.value = auth.NewSecurityHandler(oidc.NewClient(
			idp.IntrospectionUrl(),
			idp.UserInfoUrl(),
			IdpClientId,
			IdpClientSecret,
			RolesKey))
		require.NotNil(t, h.securityHandler.value)
	}
	return h.securityHandler.value
}

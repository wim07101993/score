package helpers

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"score/internal/auth"
	"score/internal/score"
	"score/internal/set"

	"github.com/stretchr/testify/require"
)

// EnsureApiServer starts the real score API in front of the harness database
// and the fake identity provider.
func (h *Harness) EnsureApiServer(t *testing.T) *httptest.Server {
	t.Helper()
	h.apiServer.mutex.Lock()
	defer h.apiServer.mutex.Unlock()

	if h.apiServer.value == nil {
		mux := http.NewServeMux()
		h.EnsureHttpServer(t).RegisterRoutes(mux)
		h.EnsureSetsHttpServer(t).RegisterRoutes(mux)

		// Not closed on test cleanup: the harness builds it once and every
		// later test reuses it, so it lives as long as the test binary.
		h.apiServer.value = httptest.NewServer(mux)
	}
	return h.apiServer.value
}

func (h *Harness) EnsureHttpServer(t *testing.T) *score.HttpServer {
	t.Helper()
	h.httpServer.mutex.Lock()
	defer h.httpServer.mutex.Unlock()

	if h.httpServer.value == nil {
		pool := h.EnsureDatabase(t)
		logger := slog.New(slog.NewTextHandler(io.Discard, nil))

		h.httpServer.value = score.NewHttpServer(
			logger,
			func(ctx context.Context) (*score.Database, error) {
				conn, err := pool.Acquire(ctx)
				if err != nil {
					return nil, err
				}
				return score.NewDatabase(logger, conn), nil
			},
			h.EnsureAuthMiddleware(t))
	}
	return h.httpServer.value
}

func (h *Harness) EnsureSetsHttpServer(t *testing.T) *set.HttpServer {
	t.Helper()
	h.setsHttpServer.mutex.Lock()
	defer h.setsHttpServer.mutex.Unlock()

	if h.setsHttpServer.value == nil {
		pool := h.EnsureDatabase(t)
		logger := slog.New(slog.NewTextHandler(io.Discard, nil))

		h.setsHttpServer.value = set.NewHttpServer(
			logger,
			func(ctx context.Context) (*set.Database, error) {
				conn, err := pool.Acquire(ctx)
				if err != nil {
					return nil, err
				}
				return set.NewDatabase(logger, conn), nil
			},
			h.EnsureAuthMiddleware(t))
	}
	return h.setsHttpServer.value
}

func (h *Harness) EnsureAuthMiddleware(t *testing.T) *auth.Middleware {
	t.Helper()
	h.authMiddleware.mutex.Lock()
	defer h.authMiddleware.mutex.Unlock()

	if h.authMiddleware.value == nil {
		idp := h.EnsureIdentityProvider(t)
		h.authMiddleware.value = auth.NewMiddleware(
			idp.IntrospectionUrl(),
			idp.UserInfoUrl(),
			IdpClientId,
			IdpClientSecret,
			RolesKey)
		require.NotNil(t, h.authMiddleware.value)
	}
	return h.authMiddleware.value
}

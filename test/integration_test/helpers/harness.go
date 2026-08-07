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
	"fmt"
	"net/http"
	"net/http/httptest"
	"score/internal/api"
	"testing"
	"time"

	"score/internal/bootstrap"
	"score/internal/storage"

	"github.com/stretchr/testify/require"
)

type Harness struct {
	*bootstrap.DependencyContainer

	DatabaseUrl string

	HttpClient         bootstrap.Provider[*http.Client]
	IdentityProvider   bootstrap.Provider[*IdentityProvider]
	TestServer         bootstrap.Provider[*httptest.Server]
	ApiClient          bootstrap.Provider[*ApiClient]
	RawClient          bootstrap.Provider[*RawClient]
	SecuritySource     bootstrap.Provider[api.SecuritySource]
	FakeSecuritySource bootstrap.Provider[*FakeSecuritySource]
}

func NewHarness(databaseUrl string) *Harness {
	h := &Harness{DatabaseUrl: databaseUrl}

	h.HttpClient = bootstrap.NewLazySingleton(h.NewHttpClient)
	h.IdentityProvider = bootstrap.NewLazySingleton(h.NewIdentityProvider)
	h.TestServer = bootstrap.NewLazySingleton(h.NewTestServer)
	h.ApiClient = bootstrap.NewFactory(h.NewApiClient)
	h.RawClient = bootstrap.NewFactory(h.NewRawClient)

	h.DependencyContainer = bootstrap.DefaultDependencyContainer(
		bootstrap.NewLazySingleton(h.NewOidcClientConfig),
		bootstrap.NewSingleton(storage.DatabaseConfig{ConnectionString: databaseUrl}),
	)

	h.MigrationsSource = bootstrap.NewSingleton(MigrationsSource)
	h.FakeSecuritySource = bootstrap.NewScopedLazySingleton(h.NewFakeSecuritySource)
	h.SecuritySource = bootstrap.NewFactory(func(ctx context.Context) (api.SecuritySource, error) {
		return h.FakeSecuritySource.Provide(ctx)
	})

	api.FullErrorInResponse.Store(true)

	return h
}

// NewScope is the harness as one test sees it. What a test may not share with
// the test running beside it — the security source that says who it is calling
// as — is built again for the scope; everything else is a plain provider and
// passes through, so the database, the identity provider and the http server
// stay the one the whole run is served from.
//
// ApiClient and SecuritySource are rebound to the scope rather than scoped:
// they are factories, and they have to resolve the scope's security source
// rather than the root's.
func (h *Harness) NewScope() *Harness {
	scoped := &Harness{
		DependencyContainer: h.DependencyContainer.NewScope(),
		DatabaseUrl:         h.DatabaseUrl,

		HttpClient:         bootstrap.ScopeProvider(h.HttpClient),
		IdentityProvider:   bootstrap.ScopeProvider(h.IdentityProvider),
		TestServer:         bootstrap.ScopeProvider(h.TestServer),
		RawClient:          bootstrap.ScopeProvider(h.RawClient),
		FakeSecuritySource: bootstrap.ScopeProvider(h.FakeSecuritySource),
	}

	scoped.ApiClient = bootstrap.NewFactory(scoped.NewApiClient)
	scoped.SecuritySource = bootstrap.NewFactory(func(ctx context.Context) (api.SecuritySource, error) {
		return scoped.FakeSecuritySource.Provide(ctx)
	})

	return scoped
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

func (h *Harness) NewApiClient(ctx context.Context) (_ *ApiClient, err error) {
	var (
		testServer     *httptest.Server
		securitySource *FakeSecuritySource
		httpClient     *http.Client
	)

	if testServer, err = h.TestServer.Provide(ctx); err != nil {
		return nil, fmt.Errorf("failed to get test server: %w", err)
	}
	// The concrete source rather than h.SecuritySource: it is handed back with
	// the client so that a test can say who it is calling as, and every client
	// gets one of its own so that two tests can be two callers at once.
	if securitySource, err = h.FakeSecuritySource.Provide(ctx); err != nil {
		return nil, fmt.Errorf("failed to get security source: %w", err)
	}
	if httpClient, err = h.HttpClient.Provide(ctx); err != nil {
		return nil, fmt.Errorf("failed to get http client: %w", err)
	}

	client, err := api.NewClient(
		testServer.URL,
		securitySource,
		api.WithClient(httpClient),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to build api client: %w", err)
	}

	return &ApiClient{Client: client, Security: securitySource}, nil
}

func (h *Harness) NewRawClient(ctx context.Context) (_ *RawClient, err error) {
	var (
		testServer *httptest.Server
		httpClient *http.Client
	)

	if testServer, err = h.TestServer.Provide(ctx); err != nil {
		return nil, fmt.Errorf("failed to get test server: %w", err)
	}
	if httpClient, err = h.HttpClient.Provide(ctx); err != nil {
		return nil, fmt.Errorf("failed to get http client: %w", err)
	}

	return &RawClient{baseUrl: testServer.URL, client: httpClient}, nil
}

func (h *Harness) NewFakeSecuritySource(ctx context.Context) (_ *FakeSecuritySource, err error) {
	return &FakeSecuritySource{}, nil
}

func Ensure[T any](t *testing.T, provider bootstrap.Provider[T], what string) T {
	t.Helper()

	value, err := provider.Provide(t.Context())
	require.NoErrorf(t, err, "failed to build the %s", what)
	require.NotNilf(t, value, "the %s was built as nil", what)
	return value
}

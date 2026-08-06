// Package helpers holds the test harness for the score integration tests.
//
// The harness owns everything a test needs to talk to a running API: a
// database, a fake identity provider, the real http server and a client. Every
// dependency is built lazily by an EnsureXxx method and reused afterwards, so a
// test only pays for what it actually touches.
package helpers

import (
	"net/http"
	"net/http/httptest"
	"sync"

	"score/internal/auth"
	"score/internal/bootstrap"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Harness struct {
	// DB and DatabaseUrl are set by TestMain before any test runs.
	DB          *pgxpool.Pool
	DatabaseUrl string

	httpClient      dependency[*http.Client]
	identityProv    dependency[*IdentityProvider]
	bootstrapper    dependency[*bootstrap.DependencyContainer]
	securityHandler dependency[*auth.SecurityHandler]
	apiHandler      dependency[http.Handler]
	apiServer       dependency[*httptest.Server]
	scoresClient    dependency[*ScoresClient]
}

type dependency[T any] struct {
	mutex sync.Mutex
	value T
}

func (d *dependency[T]) Get() T {
	return d.value
}

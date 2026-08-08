package helpers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"score/internal/oidc"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

const (
	// The credentials the API authenticates itself with when introspecting.
	IdpClientId     = "score-api"
	IdpClientSecret = "score-api-secret"

	// RolesKey is the user-info claim the roles are read from, mirroring the
	// claim Zitadel projects roles into.
	RolesKey = "urn:zitadel:iam:org:project:roles"

	IntrospectionPath = "/oauth/v2/introspect"
	UserInfoPath      = "/oidc/v1/userinfo"
)

// IdentityProvider is a fake OIDC provider. Tests mint tokens with it and it
// answers the introspection and user-info calls the auth middleware makes.
type IdentityProvider struct {
	server *httptest.Server

	mutex  sync.RWMutex
	tokens map[string]*tokenState
}

type tokenState struct {
	subject string
	name    string
	email   string
	roles   map[string]any

	// active is what the introspection endpoint reports.
	active bool
	// introspectionFails makes the introspection endpoint reject the API's own
	// credentials, simulating a misconfigured or unhappy provider.
	introspectionFails bool
	// userInfoFails makes the user-info endpoint fail for an otherwise valid
	// token.
	userInfoFails bool
}

func (h *Harness) NewIdentityProvider(ctx context.Context) (*IdentityProvider, error) {
	idp := &IdentityProvider{tokens: map[string]*tokenState{}}
	// Not closed on test cleanup: the harness builds it once and every later
	// test reuses it, so it lives as long as the test binary.
	idp.server = httptest.NewServer(http.HandlerFunc(idp.handle))
	return idp, nil
}

// NewOidcClientConfig points the API at the fake provider. It is what makes the
// container the tests build the same graph the application builds, differing
// only in which identity provider it trusts.
func (h *Harness) NewOidcClientConfig(ctx context.Context) (oidc.ClientConfig, error) {
	idp, err := h.IdentityProvider.Provide(ctx)
	if err != nil {
		return oidc.ClientConfig{}, err
	}

	return oidc.ClientConfig{
		IntrospectionUrl: idp.IntrospectionUrl(),
		UserInfoUrl:      idp.UserInfoUrl(),
		ClientId:         IdpClientId,
		ClientSecret:     IdpClientSecret,
		RolesKey:         RolesKey,
	}, nil
}

func (idp *IdentityProvider) IntrospectionUrl() string { return idp.server.URL + IntrospectionPath }
func (idp *IdentityProvider) UserInfoUrl() string      { return idp.server.URL + UserInfoPath }

// User is who a token is minted for. Every field is optional: what is left
// blank is filled in with something nobody else has, so that a test which does
// not care who it is talking as never has two of its users turn out to be one.
// A test that does care — sharing a set is the reason this exists — names the
// parts it needs to name and lets the rest be.
type User struct {
	Subject string
	Name    string
	Email   string
}

// IssueToken mints an active token for a user holding the given roles.
func (idp *IdentityProvider) IssueToken(t *testing.T, roles ...string) string {
	t.Helper()
	return idp.IssueTokenFor(t, User{}, roles...)
}

// IssueTokenFor mints an active token for the given user, holding the given
// roles.
func (idp *IdentityProvider) IssueTokenFor(t *testing.T, user User, roles ...string) string {
	t.Helper()

	claimed := map[string]any{}
	for _, role := range roles {
		// Zitadel projects a role as a map of org-id to org-domain; the API
		// only cares about the presence of the key.
		claimed[role] = map[string]any{"1": "test.localhost"}
	}

	if user.Subject == "" {
		user.Subject = uuid.NewString()
	}
	if user.Name == "" {
		user.Name = "Test User"
	}
	if user.Email == "" {
		// Tied to the subject rather than random, so that the address and the
		// subject of one user always agree, and two users never share either.
		user.Email = user.Subject + "@test.localhost"
	}

	return idp.issue(t, &tokenState{
		subject: user.Subject,
		name:    user.Name,
		email:   user.Email,
		roles:   claimed,
		active:  true,
	})
}

// IssueInactiveToken mints a token the provider reports as inactive, e.g. an
// expired or revoked one.
func (idp *IdentityProvider) IssueInactiveToken(t *testing.T) string {
	t.Helper()
	return idp.issue(t, &tokenState{subject: uuid.NewString(), name: "Test User"})
}

// IssueUnintrospectableToken mints a token whose introspection call fails. That
// is a problem between the API and the provider, not a problem with the caller.
func (idp *IdentityProvider) IssueUnintrospectableToken(t *testing.T) string {
	t.Helper()
	return idp.issue(t, &tokenState{
		subject:            uuid.NewString(),
		name:               "Test User",
		active:             true,
		introspectionFails: true,
	})
}

// IssueTokenWithoutUserInfo mints an active token the provider refuses to
// return user info for.
func (idp *IdentityProvider) IssueTokenWithoutUserInfo(t *testing.T) string {
	t.Helper()
	return idp.issue(t, &tokenState{
		subject:       uuid.NewString(),
		name:          "Test User",
		active:        true,
		userInfoFails: true,
	})
}

func (idp *IdentityProvider) issue(t *testing.T, state *tokenState) string {
	t.Helper()
	require.NotNil(t, idp.server, "the identity provider is not running")

	token := uuid.NewString()
	idp.mutex.Lock()
	defer idp.mutex.Unlock()
	idp.tokens[token] = state
	return token
}

func (idp *IdentityProvider) lookup(token string) (*tokenState, bool) {
	idp.mutex.RLock()
	defer idp.mutex.RUnlock()
	state, ok := idp.tokens[token]
	return state, ok
}

func (idp *IdentityProvider) handle(res http.ResponseWriter, req *http.Request) {
	switch req.URL.Path {
	case IntrospectionPath:
		idp.handleIntrospection(res, req)
	case UserInfoPath:
		idp.handleUserInfo(res, req)
	default:
		http.NotFound(res, req)
	}
}

func (idp *IdentityProvider) handleIntrospection(res http.ResponseWriter, req *http.Request) {
	clientId, clientSecret, ok := req.BasicAuth()
	if !ok || clientId != IdpClientId || clientSecret != IdpClientSecret {
		writeJson(res, http.StatusUnauthorized, map[string]any{"error": "invalid_client"})
		return
	}
	if err := req.ParseForm(); err != nil {
		writeJson(res, http.StatusBadRequest, map[string]any{"error": "invalid_request"})
		return
	}

	state, known := idp.lookup(req.PostFormValue("token"))
	if known && state.introspectionFails {
		writeJson(res, http.StatusUnauthorized, map[string]any{"error": "invalid_client"})
		return
	}

	writeJson(res, http.StatusOK, map[string]any{"active": known && state.active})
}

func (idp *IdentityProvider) handleUserInfo(res http.ResponseWriter, req *http.Request) {
	token := strings.TrimPrefix(req.Header.Get("Authorization"), "Bearer ")

	state, known := idp.lookup(token)
	if !known || !state.active || state.userInfoFails {
		writeJson(res, http.StatusUnauthorized, map[string]any{"error": "invalid_token"})
		return
	}

	writeJson(res, http.StatusOK, map[string]any{
		"sub":    state.subject,
		"name":   state.name,
		"email":  state.email,
		RolesKey: state.roles,
	})
}

func writeJson(res http.ResponseWriter, statusCode int, body any) {
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(statusCode)
	_ = json.NewEncoder(res).Encode(body)
}

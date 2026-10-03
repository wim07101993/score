package oidc

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// providerAnswering is a user-info endpoint that answers every call with the
// given claims.
func providerAnswering(t *testing.T, claims map[string]any) *Client {
	t.Helper()

	server := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(res).Encode(claims)
	}))
	t.Cleanup(server.Close)

	return NewClient(ClientConfig{UserInfoUrl: server.URL, IntrospectionUrl: server.URL})
}

// An address is only the caller's when the provider vouches for it. Anything
// short of a plain yes — no, nothing at all, or something that cannot be read —
// leaves it as something the caller merely said about themselves.
func TestOnlyAnAddressTheProviderVerifiedIsTheCallers(t *testing.T) {
	cases := map[string]struct {
		verified any
		want     string
	}{
		"verified":                   {verified: true, want: "bas@example.com"},
		"verified, said as text":     {verified: "true", want: "bas@example.com"},
		"not verified":               {verified: false, want: ""},
		"not verified, said as text": {verified: "false", want: ""},
		"not said at all":            {verified: nil, want: ""},
		"something else":             {verified: 1, want: ""},
	}

	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			claims := map[string]any{"sub": "bas", "email": "bas@example.com"}
			if c.verified != nil {
				claims["email_verified"] = c.verified
			}

			user, err := providerAnswering(t, claims).GetUserInfo(t.Context(), "token")
			require.NoError(t, err)

			assert.Equal(t, "bas@example.com", user.Email,
				"the address itself is still what the provider said")
			assert.Equal(t, c.want, user.VerifiedEmail())
		})
	}
}

// Every request waits on the provider before it does anything, so the client
// has to give up on one that stalls rather than wait for as long as it does.
func TestTheClientGivesUpOnAProviderThatStalls(t *testing.T) {
	assert.Equal(t, requestTimeout, NewClient(ClientConfig{}).httpClient.Timeout,
		"calls to the provider should not be allowed to take forever")

	release := make(chan struct{})
	server := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		<-release
	}))
	// Unblock the handler before closing, or Close waits for it.
	t.Cleanup(server.Close)
	t.Cleanup(func() { close(release) })

	client := NewClient(ClientConfig{UserInfoUrl: server.URL, IntrospectionUrl: server.URL})
	// The real limit is seconds; the test is about it being there at all.
	client.httpClient.Timeout = 50 * time.Millisecond

	started := time.Now()
	_, err := client.IntrospectToken(context.Background(), "token")
	assert.Error(t, err, "a provider that never answers should be an error")
	_, err = client.GetUserInfo(context.Background(), "token")
	assert.Error(t, err, "a provider that never answers should be an error")
	assert.Less(t, time.Since(started), 5*time.Second, "the client waited on the provider regardless")
}

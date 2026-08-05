// Package oidc talks to the identity provider.
//
// It is the only place that knows what those calls look like on the wire: which
// endpoint is asked, how the request is authenticated, and how the answer is
// read back. What is done with the answer — whether a token is good enough for
// an operation — is not decided here.
package oidc

import (
	"net/http"
)

// Client is the identity provider, as far as the rest of the application is
// concerned. It is safe for concurrent use and meant to be built once and
// shared: the http client underneath keeps its connections alive between calls.
type Client struct {
	// IntrospectionUrl is the endpoint that says whether a token is still good.
	IntrospectionUrl string
	// UserInfoUrl is the endpoint that says who a token belongs to.
	UserInfoUrl string
	// ClientId and ClientSecret are what this application introspects as. The
	// user info endpoint is asked with the caller's own token instead.
	ClientId     string
	ClientSecret string
	// RolesKey is the claim the provider puts the user's roles under. Which key
	// that is differs per provider, so it is configured rather than assumed.
	RolesKey string

	httpClient *http.Client
}

func NewClient(
	introspectionUrl string,
	userInfoUrl string,
	clientId string,
	clientSecret string,
	rolesKey string) *Client {
	return &Client{
		IntrospectionUrl: introspectionUrl,
		UserInfoUrl:      userInfoUrl,
		ClientId:         clientId,
		ClientSecret:     clientSecret,
		RolesKey:         rolesKey,
		httpClient:       &http.Client{},
	}
}

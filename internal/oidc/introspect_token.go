package oidc

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/pkg/errors"
)

// IntrospectionResponse is the part of the introspection answer this
// application reads. The endpoint says a good deal more about a token; none of
// it is needed to decide whether the token may still be used.
type IntrospectionResponse struct {
	IsActive bool `json:"active"`
}

// IntrospectToken asks the provider whether the token is still active.
//
// A token the provider does not recognise is not an error: it is simply not
// active. An error means the question could not be asked, which is a failure of
// this application, not of the caller.
func (c *Client) IntrospectToken(ctx context.Context, token string) (bool, error) {
	data := url.Values{}
	data.Set("token", token)

	req, err := http.NewRequestWithContext(
		ctx, http.MethodPost, c.config.IntrospectionUrl, strings.NewReader(data.Encode()))
	if err != nil {
		return false, errors.Wrap(err, "failed to create token introspection request")
	}
	req.SetBasicAuth(c.config.ClientId, c.config.ClientSecret)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return false, errors.Wrap(err, "failed to do token introspection request")
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return false, errors.Errorf(
			"token introspection failed with status %v: %s", resp.StatusCode, string(b))
	}

	var result IntrospectionResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return false, errors.Wrap(err, "could not read response from introspection request")
	}
	return result.IsActive, nil
}

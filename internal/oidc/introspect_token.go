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

type IntrospectionResponse struct {
	IsActive bool `json:"active"`
}

func (c *Client) IntrospectToken(ctx context.Context, token string) (bool, error) {
	data := url.Values{}
	data.Set("token", token)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.config.IntrospectionUrl, strings.NewReader(data.Encode()))
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

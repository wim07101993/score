package oidc

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/pkg/errors"
)

// UserInfo is who a token belongs to, as the provider tells it.
type UserInfo struct {
	Name    string
	Subject string
	Roles   map[string]any
}

// GetUserInfo asks the provider who the token belongs to.
//
// The endpoint is asked with the caller's own token, so it answers about that
// caller. A claim the provider leaves out comes back empty rather than as an
// error: what the application does about a user without a name, or without
// roles, is not for this package to decide.
func (c *Client) GetUserInfo(ctx context.Context, token string) (*UserInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.UserInfoUrl, nil)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create user info request")
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, "failed to do user info request")
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, errors.Errorf("failed to do user info request because of statuscode: %v, %s", resp.StatusCode, string(b))
	}

	userInfo := make(map[string]any)
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, errors.Wrap(err, "could not deserialize user-info response")
	}

	name, _ := (userInfo["name"]).(string)
	sub, _ := (userInfo["sub"]).(string)
	roles, _ := (userInfo[c.RolesKey]).(map[string]any)
	return &UserInfo{
		Name:    name,
		Subject: sub,
		Roles:   roles,
	}, nil
}

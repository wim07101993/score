package oidc

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type UserInfo struct {
	Name    string
	Subject string
	Roles   map[string]any
}

func (c *Client) GetUserInfo(ctx context.Context, token string) (*UserInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.config.UserInfoUrl, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create user info request: %w", err)
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to do user info request: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to do user info request because of statuscode: %v, %s", resp.StatusCode, string(b))
	}

	userInfo := make(map[string]any)
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, fmt.Errorf("could not deserialize user-info response: %w", err)
	}

	name, _ := (userInfo["name"]).(string)
	sub, _ := (userInfo["sub"]).(string)
	roles, _ := (userInfo[c.config.RolesKey]).(map[string]any)
	return &UserInfo{
		Name:    name,
		Subject: sub,
		Roles:   roles,
	}, nil
}

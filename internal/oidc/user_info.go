package oidc

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type UserInfo struct {
	Name    string
	Subject string
	Email   string
	// EmailVerified is whether the provider vouches that the caller has shown
	// they can read mail sent to Email. Most providers let anyone type any
	// address onto their own account and only mark it verified once a link in
	// a mail to it has been followed, so an address without this is nothing
	// more than something the caller said about themselves.
	EmailVerified bool
	Roles         map[string]any
}

// VerifiedEmail is the caller's address when the provider says it is theirs,
// and nothing otherwise.
//
// Sets and collections are shared by address, so whoever has an address is
// handed everything shared with it. Taking an unverified one at its word would
// let somebody put a band member's address on their own account and read the
// band's sets; an empty one matches no share at all, which is exactly what
// somebody who has not proven an address should get. They still have
// everything they own, since that goes by subject.
func (u *UserInfo) VerifiedEmail() string {
	if !u.EmailVerified {
		return ""
	}
	return u.Email
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
	email, _ := (userInfo["email"]).(string)
	roles, _ := (userInfo[c.config.RolesKey]).(map[string]any)
	return &UserInfo{
		Name:          name,
		Subject:       sub,
		Email:         email,
		EmailVerified: isTrue(userInfo["email_verified"]),
		Roles:         roles,
	}, nil
}

// isTrue reads a boolean claim. OIDC says email_verified is a JSON boolean, but
// some providers have been known to send it as the string "true", and refusing
// those would leave their users unable to see anything shared with them.
// Anything else — false, missing, or something unexpected — counts as not
// verified: the safe answer to a claim that cannot be read is no.
func isTrue(claim any) bool {
	switch value := claim.(type) {
	case bool:
		return value
	case string:
		return strings.EqualFold(value, "true")
	default:
		return false
	}
}

package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"score/internal"
	"score/internal/api"
	"score/internal/httperror"
	"strings"

	"github.com/pkg/errors"
)

const (
	RoleScoreEditor = "score_editor"
	RoleScoreViewer = "score_viewer"
)

type UserInfo struct {
	Name    string
	Subject string
	Roles   map[string]interface{}
}

type IntrospectionResponse struct {
	IsActive bool `json:"active"`
}

// SecurityHandler answers the one question the generated server asks about
// every request: may this token do this?
//
// Which roles an operation needs is not decided here — it is written down in
// the openapi document, next to the operation, and handed to us by the
// generated server.
type SecurityHandler struct {
	IntrospectionUrl string
	ClientId         string
	ClientSecret     string
	UserInfoUrl      string
	RolesKey         string
}

var _ api.SecurityHandler = (*SecurityHandler)(nil)

func NewSecurityHandler(
	introspectionUrl string,
	userInfoUrl string,
	clientId string,
	clientSecret string,
	rolesKey string) *SecurityHandler {
	return &SecurityHandler{
		IntrospectionUrl: introspectionUrl,
		UserInfoUrl:      userInfoUrl,
		ClientId:         clientId,
		ClientSecret:     clientSecret,
		RolesKey:         rolesKey,
	}
}

// HandleOAuth2 introspects the token, looks up who it belongs to, and checks
// that they hold every role the operation asks for.
//
// The roles arrive as the scopes of the operation's security requirement, which
// is where api/endpoints writes them down.
//
// A request without an authorization header, or with one that is not a bearer
// scheme, never reaches this: the generated server turns those away itself.
func (h *SecurityHandler) HandleOAuth2(
	ctx context.Context,
	operationName api.OperationName,
	t api.OAuth2) (context.Context, error) {
	if t.Token == "" {
		return ctx, httperror.New(http.StatusUnauthorized,
			api.ProblemDetailsErrorCodeInvalidCredentials,
			"authorization header is malformed. Expected 'Bearer {token}'")
	}

	isValid, err := introspectToken(h.IntrospectionUrl, h.ClientId, h.ClientSecret, t.Token)
	if err != nil {
		return ctx, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to introspect token")
	}
	if !isValid {
		return ctx, httperror.New(http.StatusUnauthorized,
			api.ProblemDetailsErrorCodeInvalidCredentials, "token not valid")
	}

	user, err := getUserInfo(h.UserInfoUrl, h.RolesKey, t.Token)
	if err != nil {
		return ctx, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get user info")
	}

	for _, role := range t.Scopes {
		if _, ok := user.Roles[role]; !ok {
			return ctx, httperror.New(http.StatusForbidden,
				api.ProblemDetailsErrorCodeMissingRole,
				fmt.Sprintf("user does not have required role to perform this action (required role: %s)", role))
		}
	}

	return context.WithValue(ctx, internal.UserInfoKey, user), nil
}

func introspectToken(endpoint string, clientId string, clientSecret string, token string) (bool, error) {
	data := url.Values{}

	data.Set("token", token)
	req, err := http.NewRequest("POST", endpoint, strings.NewReader(data.Encode()))
	if err != nil {
		return false, errors.Wrap(err, "failed to create token introspection request")
	}
	req.SetBasicAuth(clientId, clientSecret)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(req)
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

func getUserInfo(endpoint string, rolesKey string, token string) (*UserInfo, error) {
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create user info request")
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, "failed to do user info request")
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, errors.Errorf("failed to do user info request because of statuscode: %v, %s", resp.StatusCode, string(b))
	}

	userInfo := make(map[string]interface{})
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, errors.Wrap(err, "could not deserialize user-info response")
	}

	name, _ := (userInfo["name"]).(string)
	sub, _ := (userInfo["sub"]).(string)
	roles, _ := (userInfo[rolesKey]).(map[string]interface{})
	return &UserInfo{
		Name:    name,
		Subject: sub,
		Roles:   roles,
	}, nil
}

package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"score/internal"
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

type Middleware struct {
	IntrospectionUrl string
	ClientId         string
	ClientSecret     string
	UserInfoUrl      string
	RolesKey         string
}

func NewMiddleware(
	introspectionUrl string,
	userInfoUrl string,
	clientId string,
	clientSecret string,
	rolesKey string) *Middleware {
	return &Middleware{
		IntrospectionUrl: introspectionUrl,
		UserInfoUrl:      userInfoUrl,
		ClientId:         clientId,
		ClientSecret:     clientSecret,
		RolesKey:         rolesKey,
	}
}

func (m *Middleware) Authenticate(handler func(res http.ResponseWriter, req *http.Request) error) func(res http.ResponseWriter, req *http.Request) error {
	return func(res http.ResponseWriter, req *http.Request) error {
		header := req.Header.Get("Authorization")
		if header == "" {
			http.Error(res, "no authorization header", http.StatusUnauthorized)
			return errors.New("no authorization header")
		}

		split := strings.Split(header, " ")
		scheme := split[0]
		if len(split) != 2 || strings.ToLower(scheme) != "bearer" {
			http.Error(res, "authorization header is malformed. Expected 'Bearer {token}'", http.StatusUnauthorized)
			return errors.New("authorization header is malformed. Expected 'Bearer {token}'")
		}
		token := split[1]

		isValid, err := introspectToken(m.IntrospectionUrl, m.ClientId, m.ClientSecret, token)
		if err != nil {
			http.Error(res, "failed to introspect token", http.StatusInternalServerError)
			return err
		}
		if !isValid {
			http.Error(res, "token not valid", http.StatusUnauthorized)
			return errors.New("token not valid")
		}

		user, err := getUserInfo(m.UserInfoUrl, m.RolesKey, token)
		if err != nil {
			http.Error(res, "failed to get user ino", http.StatusInternalServerError)
			return err
		}

		req = req.WithContext(context.WithValue(req.Context(), internal.UserInfoKey, user))
		return handler(res, req)
	}
}

func (m *Middleware) RequireRole(role string, handler func(res http.ResponseWriter, req *http.Request) error) func(res http.ResponseWriter, req *http.Request) error {
	return func(res http.ResponseWriter, req *http.Request) error {
		userInfo, ok := req.Context().Value(internal.UserInfoKey).(*UserInfo)
		if !ok {
			http.Error(res, "no user info", http.StatusUnauthorized)
			return errors.New("no user info")
		}

		_, ok = userInfo.Roles[role]
		if !ok {
			http.Error(res,
				fmt.Sprintf("user does not have required role to perform this action (required role: %s)", role),
				http.StatusForbidden)
			return errors.Errorf("user does not have required role to perform this action (required role: %s)", role)
		}

		return handler(res, req)
	}
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

	if resp.StatusCode == http.StatusUnauthorized {
		return false, errors.Wrap(err, "failed to do token introspection because of authentication reasons")
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

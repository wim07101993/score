package auth

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strings"

	"github.com/pkg/errors"
)

type IntrospectionResponse struct {
	IsActive bool `json:"active"`
}

type Middleware struct {
	IntrospectionUrl string
	ClientId         string
	ClientSecret     string
}

func NewMiddleware(introspectionUrl string, clientId string, clientSecret string) *Middleware {
	return &Middleware{
		IntrospectionUrl: introspectionUrl,
		ClientId:         clientId,
		ClientSecret:     clientSecret,
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

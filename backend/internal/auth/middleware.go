package auth

import (
	"context"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/lestrrat-go/jwx/v2/jwt"
	"net/http"
	"strings"
)

const tokenContextKey = "authorization_token"

func Authenticate(
	issuer string,
	jwkSet jwk.Set,
	handler func(res http.ResponseWriter, req *http.Request)) func(res http.ResponseWriter, req *http.Request) {
	if jwkSet == nil {
		panic("no jwk set declared")
	}

	return func(res http.ResponseWriter, req *http.Request) {
		header := req.Header.Get("authorization")
		if header == "" {
			http.Error(res, "no authorization header", http.StatusUnauthorized)
			return
		}

		scheme, stoken, exists := strings.Cut(header, " ")
		if !exists {
			http.Error(res, "authorization header was malformed", http.StatusUnauthorized)
			return
		}
		if scheme != "bearer" {
			http.Error(res, "invalid authorization header scheme", http.StatusUnauthorized)
			return
		}

		set := jwt.WithKeySet(jwkSet)
		token, parseError := jwt.Parse([]byte(stoken), set)
		if parseError != nil {
			http.Error(res, "failed to parse jwt", http.StatusUnauthorized)
			return
		}

		validateError := jwt.Validate(token, jwt.WithIssuer(issuer))
		if validateError != nil {
			http.Error(res, "token was not issued by expected issuer", http.StatusUnauthorized)
			return
		}

		handler(res, req.WithContext(context.WithValue(req.Context(), tokenContextKey, token)))
	}
}

func FromContext(ctx context.Context) jwt.Token {
	val := ctx.Value(tokenContextKey)
	if val == nil {
		return nil
	}
	return val.(jwt.Token)
}

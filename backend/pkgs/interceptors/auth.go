package interceptors

import (
	"context"
	"errors"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/lestrrat-go/jwx/v2/jwt"
)

const TokenContextKey = "token"

func EnsureContextAuthenticated(jwkSets map[string]jwk.Set) func(ctx context.Context) (context.Context, error) {
	return func(ctx context.Context) (context.Context, error) {
		stoken, err := auth.AuthFromMD(ctx, "bearer")
		if err != nil {
			return nil, err
		}

		var token jwt.Token
		for issuer, jwkSet := range jwkSets {
			token, err = jwt.Parse([]byte(stoken), jwt.WithKeySet(jwkSet))
			if err != nil {
				continue
			}

			err = jwt.Validate(token, jwt.WithIssuer(issuer))
			if err != nil {
				continue
			}

			break
		}

		if err != nil {
			return nil, errors.New("invalid token")
		}

		return context.WithValue(ctx, TokenContextKey, token), nil
	}
}

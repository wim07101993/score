package interceptors

import (
	"context"
	"errors"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/lestrrat-go/jwx/v2/jwt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const TokenContextKey = "token"

var SkipJwtVerification bool

func EnsureContextAuthenticated(jwkSets map[string]jwk.Set) (auth.AuthFunc, error) {
	if SkipJwtVerification {
		return func(ctx context.Context) (context.Context, error) {
			stoken, err := auth.AuthFromMD(ctx, "bearer")
			if err != nil {
				return nil, err
			}

			token, err := jwt.Parse([]byte(stoken))
			if err != nil {
				return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token: %v", err.Error()))
			}
			return context.WithValue(ctx, TokenContextKey, token), nil
		}, nil
	}

	if len(jwkSets) == 0 {
		return nil, errors.New("no jwk sets provided. Cannot de auth without auth providers")
	}

	return func(ctx context.Context) (context.Context, error) {
		stoken, err := auth.AuthFromMD(ctx, "bearer")
		if err != nil {
			return nil, err
		}

		var token jwt.Token
		var parseError error
		var validateError error
		for issuer, jwkSet := range jwkSets {
			token, parseError = jwt.Parse([]byte(stoken), jwt.WithKeySet(jwkSet))
			if parseError != nil {
				continue
			}

			validateError = jwt.Validate(token, jwt.WithIssuer(issuer))
			if validateError != nil {
				continue
			}

			break
		}

		if parseError != nil {
			return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token: %v", parseError.Error()))
		}
		if validateError != nil {
			return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token (issuer): %v", validateError.Error()))
		}

		return context.WithValue(ctx, TokenContextKey, token), nil
	}, nil
}

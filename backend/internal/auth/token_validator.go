package auth

import (
	"context"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/lestrrat-go/jwx/v2/jwt"
)

const TokenContextKey = "token"
const googleIssuer = "https://accounts.google.com"

var validationOptions = jwt.WithIssuer(googleIssuer)

type TokenValidator struct {
	jwkSet jwk.Set
}

func NewTokenValidator(jwkSet jwk.Set) *TokenValidator {
	return &TokenValidator{
		jwkSet: jwkSet,
	}
}

func (tv *TokenValidator) EnsureContextAuthenticated(ctx context.Context) (context.Context, error) {
	stoken, err := auth.AuthFromMD(ctx, "bearer")
	if err != nil {
		return nil, err
	}
	token, err := jwt.Parse([]byte(stoken), jwt.WithKeySet(tv.jwkSet))
	if err != nil {
		return nil, err
	}

	err = jwt.Validate(token, validationOptions)
	if err != nil {
		return nil, err
	}

	return context.WithValue(ctx, TokenContextKey, token), nil
}

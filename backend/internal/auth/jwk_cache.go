package auth

import (
	"context"
	"fmt"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"time"
)

const googleCerts = `https://www.googleapis.com/oauth2/v3/certs`

func CreateGoogleJwkSet() (jwk.Set, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	c := jwk.NewCache(ctx)
	err := c.Register(googleCerts, jwk.WithMinRefreshInterval(1*time.Hour))
	if err != nil {
		return nil, err
	}
	_, err = c.Refresh(ctx, googleCerts)
	if err != nil {
		fmt.Printf("failed to refresh google JWKS: %s\n", err)
		return nil, err
	}

	return jwk.NewCachedSet(c, googleCerts), nil
}

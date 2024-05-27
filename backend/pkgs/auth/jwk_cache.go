package auth

import (
	"context"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"time"
)

const googleCerts = `https://www.googleapis.com/oauth2/v3/certs`
const googleIssuer = "https://accounts.google.com"

func CreateJwkCache() (*jwk.Cache, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	c := jwk.NewCache(ctx)
	err := c.Register(googleCerts, jwk.WithMinRefreshInterval(1*time.Hour))
	if err != nil {
		return nil, err
	}

	_, err = c.Refresh(ctx, googleCerts)
	if err != nil {
		return nil, err
	}

	return c, err
}

func JwkCachedSets(cache *jwk.Cache) map[string]jwk.Set {
	return map[string]jwk.Set{
		googleIssuer: jwk.NewCachedSet(cache, googleCerts),
	}
}

package auth

import (
	"context"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"time"
)

var GoogleConfig = Config{
	CertsUrl: `https://www.googleapis.com/oauth2/v3/certs`,
	Issuer:   "https://accounts.google.com",
}

type Config struct {
	CertsUrl        string
	Issuer          string
	RefreshInterval time.Duration
}

func CreateJwkCache(configs []Config) (*jwk.Cache, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	c := jwk.NewCache(ctx)

	for _, config := range configs {
		err := c.Register(config.CertsUrl, jwk.WithMinRefreshInterval(config.RefreshInterval))
		if err != nil {
			return nil, err
		}
		_, err = c.Refresh(ctx, config.CertsUrl)
		if err != nil {
			return nil, err
		}
	}

	return c, nil
}

func JwkCachedSets(config []Config, cache *jwk.Cache) map[string]jwk.Set {
	m := make(map[string]jwk.Set)
	for _, config := range config {
		m[config.Issuer] = jwk.NewCachedSet(cache, config.CertsUrl)
	}
	return m
}

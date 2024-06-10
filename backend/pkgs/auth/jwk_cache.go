package auth

import (
	"context"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"time"
)

func CreateJwkCache(configs []Config) (*jwk.Cache, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	c := jwk.NewCache(ctx)

	for _, config := range configs {
		err := c.Register(config.JwksUrl, jwk.WithMinRefreshInterval(15*time.Minute))
		if err != nil {
			return nil, err
		}
		_, err = c.Refresh(ctx, config.JwksUrl)
		if err != nil {
			return nil, err
		}
	}

	return c, nil
}

func JwkCachedSets(config []Config, cache *jwk.Cache) map[string]jwk.Set {
	m := make(map[string]jwk.Set)
	for _, config := range config {
		m[config.Issuer] = jwk.NewCachedSet(cache, config.JwksUrl)
	}
	return m
}

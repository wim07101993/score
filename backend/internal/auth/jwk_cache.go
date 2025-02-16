package auth

import (
	"context"
	"encoding/json"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/pkg/errors"
	"net/http"
	"time"
)

func CreateJwkCache(issuer string) (jwk.Set, error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cache := jwk.NewCache(ctx)

	resp, err := http.Get(issuer + "/.well-known/openid-configuration")
	if err != nil {
		return nil, errors.Wrap(err, "failed to fetch OpenID Connect configuration")
	}
	defer func() {
		err := resp.Body.Close()
		if err != nil {
			print(err)
		}
	}()

	doc := &struct {
		JwkUri string `json:"jwks_uri"`
	}{}
	err = json.NewDecoder(resp.Body).Decode(doc)
	if err != nil {
		return nil, errors.Wrap(err, "failed to parse OpenID Connect configuration")
	}

	err = cache.Register(doc.JwkUri, jwk.WithMinRefreshInterval(15*time.Minute))
	if err != nil {
		return nil, err
	}
	_, err = cache.Refresh(ctx, doc.JwkUri)
	if err != nil {
		return nil, err
	}

	return jwk.NewCachedSet(cache, doc.JwkUri), nil
}

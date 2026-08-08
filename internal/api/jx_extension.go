package api

import (
	"encoding/json"

	"github.com/go-faster/jx"
)

func AddToAdditionalProperties(m map[string]jx.Raw, key string, val any) error {
	jserr, err := json.Marshal(val)
	if err != nil {
		return err
	}
	m[key] = jserr
	return nil
}

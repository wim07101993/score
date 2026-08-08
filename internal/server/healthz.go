package server

import (
	"context"
	"strings"

	"score/internal/api"
)

func (h *Handler) Healthz(context.Context, api.HealthzParams) (api.HealthzRes, error) {
	return &api.HealthzOK{Data: strings.NewReader("OK")}, nil
}

package server

import (
	"context"
	"strings"

	"score/internal/api"
)

// Healthz answers as long as the server is serving.
//
// It says nothing about the database on purpose: this is what tells a load
// balancer whether to send requests here, and a server that cannot reach the
// database still answers them — with the failure that says so.
func (h *Handler) Healthz(ctx context.Context, params api.HealthzParams) (api.HealthzRes, error) {
	return &api.HealthzOK{Data: strings.NewReader("OK")}, nil
}

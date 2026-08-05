// Package health is the health slice of the API: whether the server is up.
// What it serves is described in api/endpoints/healthz.
package health

import (
	"context"
	"strings"

	"score/internal/api"
)

// Handler implements the health operations of the openapi document.
type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

// Healthz answers as long as the server is serving.
//
// It says nothing about the database on purpose: this is what tells a load
// balancer whether to send requests here, and a server that cannot reach the
// database still answers them — with the failure that says so.
func (h *Handler) Healthz(ctx context.Context) (api.HealthzRes, error) {
	return &api.HealthzOK{Data: strings.NewReader("OK")}, nil
}

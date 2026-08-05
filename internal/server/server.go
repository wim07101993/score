// Package server puts the API together.
//
// The generated server calls one Handler for every operation of the openapi
// document, but the operations themselves belong to the slices that implement
// them — one per part of that document. This is where those slices are joined
// back into the one handler ogen asks for, and where what belongs to no single
// one of them is settled: how a failure is answered, what is logged, and the
// headers a browser needs.
package server

import (
	"context"
	"log/slog"
	"net/http"

	"score/internal/api"
	"score/internal/auth"
	"score/internal/health"
	"score/internal/logging"
	"score/internal/score"
)

// handler is the whole API: every slice of it, side by side.
type handler struct {
	scores *score.Handler
	health *health.Handler

	logger *slog.Logger
}

var _ api.Handler = (*handler)(nil)

// New builds the API and everything around it, ready to be served.
func New(
	logger *slog.Logger,
	db score.DatabaseFactory,
	security *auth.SecurityHandler) (http.Handler, error) {
	h := &handler{
		scores: score.NewHandler(db),
		health: health.NewHandler(),
		logger: logger,
	}

	generated, err := api.NewServer(h, security,
		api.WithErrorHandler(h.handleError),
		api.WithNotFound(h.handleNotFound),
		api.WithMethodNotAllowed(h.handleMethodNotAllowed),
		api.WithMiddleware(score.RememberAccept))
	if err != nil {
		return nil, err
	}

	return cors(logging.Wrap(logger, generated)), nil
}

// The operations, each handed to the slice it belongs to. Written out rather
// than embedded, so that this reads as what it is: the table of contents of the
// API, saying which part of the code answers which part of the document.

func (h *handler) GetScore(ctx context.Context, params api.GetScoreParams) (api.GetScoreRes, error) {
	return h.scores.GetScore(ctx, params)
}

func (h *handler) PutScore(ctx context.Context, req api.PutScoreReq, params api.PutScoreParams) (api.PutScoreRes, error) {
	return h.scores.PutScore(ctx, req, params)
}

func (h *handler) ListScores(ctx context.Context, params api.ListScoresParams) (api.ListScoresRes, error) {
	return h.scores.ListScores(ctx, params)
}

func (h *handler) Healthz(ctx context.Context) (api.HealthzRes, error) {
	return h.health.Healthz(ctx)
}

// cors answers a browser that asks whether it may talk to us, and tells every
// other response that it may.
func cors(handler http.Handler) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Access-Control-Allow-Origin", "*")
		res.Header().Set("Access-Control-Allow-Headers", "*")
		res.Header().Set("Access-Control-Allow-Methods", "*")
		if req.Method == http.MethodOptions {
			_, _ = res.Write([]byte("OK"))
			return
		}
		handler.ServeHTTP(res, req)
	}
}

// Package server is the API: every operation of the openapi document, and
// everything it takes to answer one over http.
//
// This is the only layer that knows this application is served over http at
// all. There is a file per operation, holding what that operation reads out of
// the request and what it answers with; what belongs to no single one of them
// is settled here and in errors.go: how a failure is answered, what is logged,
// and the headers a browser needs.
//
// What the operations do to the stored music — every query, and the model of a
// score they read back — is in internal/score, which knows nothing about any
// of this.
package server

import (
	"log/slog"
	"net/http"

	"score/internal/api"
	"score/internal/auth"
	"score/internal/logging"
	"score/internal/score"
)

// handler is the whole API: every operation of the openapi document, served
// off the one store they all share.
type handler struct {
	db     score.DatabaseFactory
	logger *slog.Logger
}

var _ api.Handler = (*handler)(nil)

// New builds the API and everything around it, ready to be served.
func New(
	logger *slog.Logger,
	db score.DatabaseFactory,
	security *auth.SecurityHandler) (http.Handler, error) {
	h := &handler{
		db:     db,
		logger: logger,
	}

	generated, err := api.NewServer(h, security,
		api.WithErrorHandler(h.handleError),
		api.WithNotFound(h.handleNotFound),
		api.WithMethodNotAllowed(h.handleMethodNotAllowed),
		api.WithMiddleware(setAcceptHeaderToContextMiddleware))
	if err != nil {
		return nil, err
	}

	return cors(logging.Wrap(logger, generated)), nil
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

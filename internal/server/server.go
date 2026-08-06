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
	"net/http"
	"score/internal/storage"

	"score/internal/api"
)

// Handler is the whole API: every operation of the openapi document, served
// off the one store they all share.
//
// It holds no logger: the logging middleware puts one in the context of every
// request, already carrying that request's correlation id, and the operations
// write to that one.
type Handler struct {
	db storage.DBConnProvider
}

var _ api.Handler = (*Handler)(nil)

func New(db storage.DBConnProvider) *Handler {
	return &Handler{
		db: db,
	}
}

// Cors answers a browser that asks whether it may talk to us, and tells every
// other response that it may.
func Cors(handler http.Handler) http.HandlerFunc {
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

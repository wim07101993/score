package logging

import (
	"context"
	"log/slog"
	"net/http"
	"score/internal"

	"github.com/google/uuid"
)

// Wrap logs every request that goes in and every response that comes back out,
// and gives the request a correlation id to tie the two together.
//
// Why a request failed is logged where that is known: by the handler that
// answered it, under the same correlation id.
func Wrap(l *slog.Logger, handler http.Handler) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		correlationId := callerCorrelationId(req)
		if correlationId == "" {
			correlationId = uuid.New().String()
		}
		l.Info("handle http request",
			slog.String("method", req.Method),
			slog.String("pattern", req.Pattern),
			slog.String("uri", req.RequestURI),
			slog.String("correlationId", correlationId))

		req = req.WithContext(context.WithValue(req.Context(), internal.CorrelationIdKey, correlationId))
		loggingRes := NewResponseWriter(l, res, correlationId)
		defer loggingRes.Flush()

		handler.ServeHTTP(loggingRes, req)
	}
}

// callerCorrelationId is the correlation id the caller asked its request to be
// tied together under, if it asked for one this server is willing to use.
//
// Only a uuid is: the id ends up in the log and, when the request fails, in the
// answer as well, so it is a string the caller chooses that this server then
// repeats. Anything but a uuid is dropped and one is made up instead.
func callerCorrelationId(req *http.Request) string {
	asked := req.Header.Get("X-Correlation-ID")
	if _, err := uuid.Parse(asked); err != nil {
		return ""
	}
	return asked
}

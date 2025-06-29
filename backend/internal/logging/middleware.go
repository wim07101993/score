package logging

import (
	"context"
	"github.com/google/uuid"
	"log/slog"
	"net/http"
	"score/backend/internal"
)

func Wrap(l *slog.Logger, handler func(res http.ResponseWriter, req *http.Request) error) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		correlation := uuid.New().String()
		l.Info("handle http request",
			slog.String("method", req.Method),
			slog.String("pattern", req.Pattern),
			slog.String("uri", req.RequestURI),
			slog.String("correlationId", correlation))

		req = req.WithContext(context.WithValue(req.Context(), internal.CorrelationIdKey, correlation))
		loggingRes := NewResponseWriter(l, res, correlation)
		defer loggingRes.Flush()

		loggingRes.Err = handler(loggingRes, req)
	}
}

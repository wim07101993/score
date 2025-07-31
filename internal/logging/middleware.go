package logging

import (
	"context"
	"github.com/google/uuid"
	"log/slog"
	"net/http"
	"score/internal"
)

func Wrap(l *slog.Logger, handler func(res http.ResponseWriter, req *http.Request) error) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		correlationId := req.Header.Get("X-Correlation-ID")
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

		loggingRes.Err = handler(loggingRes, req)
	}
}

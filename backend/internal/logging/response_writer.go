package logging

import (
	"log/slog"
	"net/http"
)

type ResponseWriter struct {
	logger        *slog.Logger
	response      http.ResponseWriter
	statusCode    int
	correlationId string
	Err           error
}

func NewResponseWriter(
	logger *slog.Logger,
	response http.ResponseWriter,
	correlationId string) *ResponseWriter {
	return &ResponseWriter{
		logger:        logger,
		response:      response,
		correlationId: correlationId,
	}
}

func (w *ResponseWriter) Header() http.Header {
	return w.response.Header()
}
func (w *ResponseWriter) Write(bs []byte) (int, error) {
	return w.response.Write(bs)
}
func (w *ResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.response.WriteHeader(statusCode)
}

func (w *ResponseWriter) Flush() {
	switch {
	case w.statusCode >= 500:
		w.logger.Error("http request failed with server error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.statusCode >= 400:
		w.logger.Info("http request failed with client error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.statusCode == 0:
		w.logger.Warn("unknown http response (response was not http.response)",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.Err != nil:
		w.logger.Warn("http request succeeded with error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	default:
		w.logger.Info("http request succeeded", slog.String("correlationId", w.correlationId))
	}
}

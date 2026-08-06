package logging

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/google/uuid"
	slogctx "github.com/veqryn/slog-context"
)

// WithLogger puts the logger every request is served under into its context,
// so that Wrap and everything below it can reach it without being handed one.
//
// It is the one place the root logger is injected. Without it the context
// carries no logger and slogctx falls back to slog.Default().
func WithLogger(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r.WithContext(slogctx.NewCtx(r.Context(), logger)))
	})
}

func WithRequestIdentification(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := uuid.NewString()
		r = r.WithContext(RequestIdToContext(r.Context(), id))
		next.ServeHTTP(w, r)
	})
}

type requestId struct{}

func RequestIdToContext(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestId{}, id)
}

func RequestIdFromContext(ctx context.Context) (string, bool) {
	v, ok := ctx.Value(requestId{}).(string)
	return v, ok
}

type correlationId struct{}

func CorrelationIdToContext(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, correlationId{}, id)
}

func CorrelationIdFromContext(ctx context.Context) (string, bool) {
	v, ok := ctx.Value(correlationId{}).(string)
	return v, ok
}

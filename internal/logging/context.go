package logging

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

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

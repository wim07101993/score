package logging

import (
	"bytes"
	"context"
	"log/slog"
	"net/http"
	"score/internal/api"
	"time"

	"github.com/google/uuid"
	"github.com/ogen-go/ogen/middleware"
	slogctx "github.com/veqryn/slog-context"
)

// Wrap logs every request that goes in and every response that comes back out,
// and gives the request a correlation id to tie the two together.
//
// This is also where the logger everything below here writes to is decided. It
// goes into the request's context already carrying the correlation id, so that
// every line logged while this request is being served is tied to it without
// anyone downstream having to remember to say so — or having to be handed a
// logger to say it with. They reach it with slogctx.FromCtx, or write to it
// straight away with slogctx.Info and friends.
//
// Why a request failed is logged where that is known: by the handler that
// answered it, under the same correlation id.
func Wrap(handler http.Handler) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		correlationId := callerCorrelationId(req)
		if correlationId == "" {
			correlationId = uuid.NewString()
		}

		requestId := uuid.NewString()

		logger := slogctx.FromCtx(req.Context()).With(
			slog.String("request_id", requestId),
			slog.String("correlation_id", correlationId))

		ctx := CorrelationIdToContext(req.Context(), correlationId)
		ctx = RequestIdToContext(ctx, requestId)
		ctx = slogctx.NewCtx(ctx, logger)

		req = req.WithContext(ctx)

		logger.Info("handle http request",
			slog.String("method", req.Method),
			slog.String("pattern", req.Pattern),
			slog.String("uri", req.RequestURI))

		start := time.Now()

		// Already set the operation id so that the value exists on the context.
		// Since the value is wrapped, it can be set by the ogen middleware and
		// retrieved later in this function. Since ogen middleware always runs
		// after net/http middleware, this will not overwrite anything
		ctx = withOperationIDContext(ctx, "")

		loggingRes := &loggingResponseWriter{
			ResponseWriter: res,
			errorBody:      bytes.NewBuffer(nil),
		}
		handler.ServeHTTP(loggingRes, req)

		if loggingRes.statusCode == 0 {
			loggingRes.statusCode = http.StatusOK
		}

		operationID, _ := getOperationIDContext(ctx)

		duration := time.Since(start)
		attrs := []any{
			slog.Int("status_code", loggingRes.statusCode),
			slog.Duration("duration", duration),
			slog.String("operation_id", operationID),
		}

		if loggingRes.statusCode < http.StatusBadRequest {
			logger.Info("handled http request", attrs...)
			return
		}

		if code := extractWireErrorCode(loggingRes.errorBody.Bytes()); code != "" {
			attrs = append(attrs, slog.String("error_code", code))
		}
		if loggingRes.statusCode >= http.StatusInternalServerError {
			logger.Error("request failed", attrs...)
			return
		}
		logger.Warn("request rejected", attrs...)

	}
}

func callerCorrelationId(req *http.Request) string {
	asked := req.Header.Get("X-Correlation-ID")
	if _, err := uuid.Parse(asked); err != nil {
		return ""
	}
	return asked
}

type operationIDContextKey struct {
}

type operationIDWrapper struct {
	operationID string
}

func AddOperationIdToContext() api.Middleware {
	return func(req middleware.Request, next middleware.Next) (middleware.Response, error) {
		req.SetContext(withOperationIDContext(req.Context, req.OperationID))
		return next(req)
	}
}

func withOperationIDContext(ctx context.Context, operationID string) context.Context {
	wrapper, ok := ctx.Value(operationIDContextKey{}).(*operationIDWrapper)
	if ok {
		wrapper.operationID = operationID
		return ctx
	}

	return context.WithValue(ctx, operationIDContextKey{}, &operationIDWrapper{operationID: operationID})
}

func getOperationIDContext(ctx context.Context) (string, bool) {
	wrapper, ok := ctx.Value(operationIDContextKey{}).(*operationIDWrapper)
	if !ok {
		return "", false
	}
	return wrapper.operationID, true
}

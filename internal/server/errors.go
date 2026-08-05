package server

import (
	"context"
	"log/slog"
	"mime"
	"net/http"

	"score/internal"
	"score/internal/api"
	"score/internal/httperror"

	"github.com/go-faster/jx"
)

// NewError turns whatever went wrong into the answer the caller gets. Nearly
// every failure passes through here: the ones the generated server ran into
// while it was reading the request, and the ones the operations returned. What
// it answers with is described in api/schemas/problem_details.yaml.
func (h *handler) NewError(ctx context.Context, err error) *api.XxxUnknownErrorStatusCode {
	status, code, detail := httperror.Answer(err)
	correlationId, _ := ctx.Value(internal.CorrelationIdKey).(string)

	h.logFailure(ctx, status, err)

	return &api.XxxUnknownErrorStatusCode{
		StatusCode: status,
		Response: api.ProblemDetails{
			// Every failure this server answers is about:blank, RFC 9457's way
			// of saying a problem is its status code and nothing more. What
			// tells them apart is the errorCode below.
			Type:   "about:blank",
			Title:  http.StatusText(status),
			Status: status,
			Detail: detail,
			// The id the failure was logged under, so that a caller reporting
			// one can be answered with what actually happened. It is a uuid the
			// server either made up or accepted from the caller, and this is
			// how a uuid is written as a URI.
			Instance:  "urn:uuid:" + correlationId,
			ErrorCode: code,
		},
	}
}

// handleError answers the failures the generated server does not hand to
// NewError itself, so that those are answered in the same shape as the rest.
func (h *handler) handleError(ctx context.Context, res http.ResponseWriter, req *http.Request, err error) {
	if isUnreadableMediaType(req) {
		err = httperror.Wrap(err, http.StatusUnsupportedMediaType,
			api.ProblemDetailsErrorCodeUnsupportedMediaType, "content-type not supported")
	}
	writeError(res, h.NewError(ctx, err))
}

func (h *handler) handleNotFound(res http.ResponseWriter, req *http.Request) {
	writeError(res, h.NewError(req.Context(),
		httperror.New(http.StatusNotFound,
			api.ProblemDetailsErrorCodeEndpointNotFound, "no such endpoint")))
}

func (h *handler) handleMethodNotAllowed(res http.ResponseWriter, req *http.Request, allowed string) {
	res.Header().Set("Allow", allowed)
	writeError(res, h.NewError(req.Context(),
		httperror.New(http.StatusMethodNotAllowed,
			api.ProblemDetailsErrorCodeMethodNotAllowed, "method not allowed on this endpoint")))
}

func (h *handler) logFailure(ctx context.Context, status int, err error) {
	correlationId, _ := ctx.Value(internal.CorrelationIdKey).(string)
	attrs := []any{
		slog.Any("error", err),
		slog.Int("status", status),
		slog.String("correlationId", correlationId),
	}

	if status >= http.StatusInternalServerError {
		h.logger.Error("failed to handle http request", attrs...)
		return
	}
	h.logger.Info("refused http request", attrs...)
}

// writeError answers with a failure the generated server is not writing for us,
// in the same media type and with the same encoder it would have used. Problem
// details carry members beyond the five RFC 9457 names, and only the generated
// encoder knows how to write those out flat alongside the rest.
func writeError(res http.ResponseWriter, err *api.XxxUnknownErrorStatusCode) {
	res.Header().Set("Content-Type", "application/problem+json")
	res.WriteHeader(err.StatusCode)

	encoder := new(jx.Encoder)
	err.Response.Encode(encoder)
	_, _ = encoder.WriteTo(res)
}

// isUnreadableMediaType tells whether a request failed over the media type it
// was sent in. A request without a Content-Type is one of those: it does not
// say what it carries, so the server cannot read it.
func isUnreadableMediaType(req *http.Request) bool {
	if req.Method == http.MethodGet || req.Method == http.MethodHead {
		return false
	}
	_, _, err := mime.ParseMediaType(req.Header.Get("Content-Type"))
	return err != nil
}

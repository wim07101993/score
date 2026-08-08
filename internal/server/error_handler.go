package server

import (
	"context"
	"mime"
	"net/http"
	"score/internal/api"
	"score/internal/logging"

	"github.com/go-faster/errors"
	"github.com/ogen-go/ogen/ogenerrors"
	slogctx "github.com/veqryn/slog-context"
)

func ErrorHandler(ctx context.Context, w http.ResponseWriter, req *http.Request, err error) {
	pderr := withInstance(ctx, requestErrToProblemDetails(req, err))

	pderr.Log(ctx)

	data, err := new(pderr.ProblemDetails(ctx)).MarshalJSON()
	if err != nil {
		slogctx.Error(ctx, "failed to marshal error response", slogctx.Err(err))
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(pderr.Status)
	if _, err = w.Write(data); err != nil {
		slogctx.Error(ctx, "failed to write error response", slogctx.Err(err))
	}
}

func requestErrToProblemDetails(req *http.Request, err error) api.ProblemDetailsError {
	var problemDetailsErr api.ProblemDetailsError
	if errors.As(err, &problemDetailsErr) {
		return problemDetailsErr
	}

	var decodeErr *ogenerrors.DecodeRequestError
	if errors.As(err, &decodeErr) && !hasParsableMediaType(req) {
		return ErrUnsupportedMediaType.WithParent(err)
	}

	var ogenErr ogenerrors.Error
	if errors.As(err, &ogenErr) {
		return ogenErrToProblemDetails(ogenErr)
	}

	return ErrUnknown.WithParent(err)
}

func errToProblemDetails(err error) api.ProblemDetailsError {
	var problemDetailsErr api.ProblemDetailsError
	if errors.As(err, &problemDetailsErr) {
		return problemDetailsErr
	}

	var ogenErr ogenerrors.Error
	if errors.As(err, &ogenErr) {
		return ogenErrToProblemDetails(ogenErr)
	}

	return ErrUnknown.WithParent(err)
}

func ogenErrToProblemDetails(err ogenerrors.Error) api.ProblemDetailsError {
	status := ogenerrors.ErrorCode(err)
	if status < http.StatusInternalServerError {
		return api.NewProblemDetailsError(status, errorCodeOfStatus(status), err.Error()).
			WithParent(err)
	}

	return ErrUnknown.WithParent(err)
}

func errorCodeOfStatus(status int) api.ProblemDetailsErrorCode {
	switch status {
	case http.StatusUnauthorized:
		return api.ProblemDetailsErrorCodeInvalidCredentials
	case http.StatusForbidden:
		return api.ProblemDetailsErrorCodeMissingRole
	case http.StatusNotFound:
		return api.ProblemDetailsErrorCodeEndpointNotFound
	case http.StatusMethodNotAllowed:
		return api.ProblemDetailsErrorCodeMethodNotAllowed
	case http.StatusUnsupportedMediaType:
		return api.ProblemDetailsErrorCodeUnsupportedMediaType
	default:
		return api.ProblemDetailsErrorCodeInvalidRequest
	}
}

func hasParsableMediaType(req *http.Request) bool {
	_, _, err := mime.ParseMediaType(req.Header.Get("Content-Type"))
	return err == nil
}

func withInstance(ctx context.Context, pderr api.ProblemDetailsError) api.ProblemDetailsError {
	correlationId, ok := logging.CorrelationIdFromContext(ctx)
	if !ok {
		return pderr
	}
	pderr.Instance = "urn:uuid:" + correlationId
	return pderr
}

func NotFound(w http.ResponseWriter, req *http.Request) {
	ErrorHandler(req.Context(), w, req, ErrEndpointNotFound)
}

func MethodNotAllowed(w http.ResponseWriter, req *http.Request, allowed string) {
	w.Header().Set("Allow", allowed)
	ErrorHandler(req.Context(), w, req, ErrMethodNotAllowed)
}

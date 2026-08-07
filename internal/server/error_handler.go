package server

import (
	"context"
	"mime"
	"net/http"
	"score/internal/api"

	"github.com/go-faster/errors"
	"github.com/ogen-go/ogen/ogenerrors"
	slogctx "github.com/veqryn/slog-context"
)

func ErrorHandler(ctx context.Context, w http.ResponseWriter, req *http.Request, err error) {
	pderr := errToProblemDetails(req, err)

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

func errToProblemDetails(req *http.Request, err error) api.ProblemDetailsError {
	var problemDetailsErr api.ProblemDetailsError
	if errors.As(err, &problemDetailsErr) {
		return problemDetailsErr
	}

	var decodeErr *ogenerrors.DecodeRequestError
	if errors.As(err, &decodeErr) {
		if _, _, err := mime.ParseMediaType(req.Header.Get("Content-Type")); err != nil {
			return ErrUnsupportedMediaType
		}
	}

	return ErrUnknown.WithParent(err)
}

func NotFound(w http.ResponseWriter, req *http.Request) {
	ErrorHandler(req.Context(), w, req, ErrEndpointNotFound)
}

func MethodNotAllowed(w http.ResponseWriter, req *http.Request, allowed string) {
	w.Header().Set("Allow", allowed)
	ErrorHandler(req.Context(), w, req, ErrMethodNotAllowed)
}

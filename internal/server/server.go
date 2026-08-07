package server

import (
	"context"
	"errors"
	"score/internal/storage"

	"score/internal/api"

	"github.com/ogen-go/ogen/ogenerrors"
)

type Handler struct {
	db storage.DBConnProvider
}

var _ api.Handler = (*Handler)(nil)

func New(db storage.DBConnProvider) *Handler {
	return &Handler{
		db: db,
	}
}
func (h *Handler) NewError(ctx context.Context, err error) *api.XxxUnknownErrorStatusCode {
	problemDetails := withInstance(ctx, errToProblemDetails(err))

	problemDetails.Log(ctx)

	return &api.XxxUnknownErrorStatusCode{
		StatusCode: problemDetails.Status,
		Response:   problemDetails.ProblemDetails(ctx),
	}
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

	return ErrUnexpected.WithParent(err)
}

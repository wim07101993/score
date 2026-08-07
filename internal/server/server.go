package server

import (
	"context"
	"errors"
	"score/internal/storage"

	"score/internal/api"
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
	var problemDetails api.ProblemDetailsError
	if !errors.As(err, &problemDetails) {
		problemDetails = ErrUnknown.WithParent(err)
	}

	problemDetails.Log(ctx)

	return &api.XxxUnknownErrorStatusCode{
		StatusCode: problemDetails.Status,
		Response:   problemDetails.ProblemDetails(ctx),
	}
}

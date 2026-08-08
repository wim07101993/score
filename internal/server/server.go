package server

import (
	"context"
	"fmt"
	"net/http"
	"score/internal/api"
	"score/internal/storage"
	"time"
)

type Config struct {
	Port                int
	MaxRequestBodyBytes int64
}

const (
	readHeaderTimeout = 10 * time.Second
	readTimeout       = 60 * time.Second
	writeTimeout      = 120 * time.Second
	idleTimeout       = 120 * time.Second
)

func NewHttpServer(config Config, handler http.Handler) *http.Server {
	return &http.Server{
		Addr:              fmt.Sprintf(":%d", config.Port),
		Handler:           handler,
		ReadHeaderTimeout: readHeaderTimeout,
		ReadTimeout:       readTimeout,
		WriteTimeout:      writeTimeout,
		IdleTimeout:       idleTimeout,
	}
}

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

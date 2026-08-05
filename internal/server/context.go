package server

import (
	"context"

	"github.com/ogen-go/ogen/middleware"
)

type contextKey int

const acceptHeaderKey contextKey = iota

func setAcceptHeaderToContextMiddleware(req middleware.Request, next middleware.Next) (middleware.Response, error) {
	req.SetContext(context.WithValue(req.Context, acceptHeaderKey, req.Raw.Header.Get("Accept")))
	return next(req)
}

func getAcceptHeaderFromContext(ctx context.Context) string {
	accept, _ := ctx.Value(acceptHeaderKey).(string)
	return accept
}

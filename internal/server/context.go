package server

import (
	"context"

	"github.com/ogen-go/ogen/middleware"
)

type contextKey int

const acceptHeaderKey contextKey = iota

// SetAcceptHeaderToContext keeps the Accept header of a request within reach of
// the operation handling it.
//
// GetScore answers in the media type that was asked for, and a generated
// handler is given the parameters of a request rather than the request itself.
// It is put in front of the operations where the api server is assembled.
func SetAcceptHeaderToContext(req middleware.Request, next middleware.Next) (middleware.Response, error) {
	req.SetContext(context.WithValue(req.Context, acceptHeaderKey, req.Raw.Header.Get("Accept")))
	return next(req)
}

func getAcceptHeaderFromContext(ctx context.Context) string {
	accept, _ := ctx.Value(acceptHeaderKey).(string)
	return accept
}

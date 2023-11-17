package grpc

import (
	"context"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"strings"
)

func IsContextAuthenticated(ctx context.Context) (context.Context, error) {
	token, err := auth.AuthFromMD(ctx, "bearer")
	if err != nil {
		return nil, err
	}
	// TODO: This is example only, perform proper Oauth/OIDC verification!
	if token != "yolo" {
		return nil, status.Error(codes.Unauthenticated, "invalid auth token")
	}
	return ctx, nil
}

func ShouldAuthenticate(ctx context.Context, callMeta interceptors.CallMeta) bool {
	return strings.HasPrefix(callMeta.Service, "grpc.reflection")
}

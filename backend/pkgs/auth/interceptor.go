package auth

import (
	"context"
	"errors"
	"fmt"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"github.com/lestrrat-go/jwx/v2/jwt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"strings"
)

const TokenContextKey = "token"

var SkipJwtVerification bool

func tokenFromMetadata(ctx context.Context) (string, error) {
	md, exists := metadata.FromIncomingContext(ctx)
	if !exists {
		return "", status.Error(codes.Unauthenticated, fmt.Sprintf("no authorization header"))
	}

	headers := md.Get("authorization")
	if headers == nil || len(headers) == 0 {
		return "", status.Error(codes.Unauthenticated, fmt.Sprintf("no authorization header"))
	}

	scheme, stoken, exists := strings.Cut(headers[0], " ")
	if !exists {
		return "", status.Error(codes.Unauthenticated, fmt.Sprintf("empty authorization header"))
	}

	if scheme != "bearer" {
		return "", status.Error(codes.Unauthenticated, fmt.Sprintf("invalid authorization header scheme"))
	}

	return stoken, nil
}

func authenticateContext(ctx context.Context, jwkSets map[string]jwk.Set) (context.Context, error) {
	if SkipJwtVerification {
		stoken, err := tokenFromMetadata(ctx)
		if err != nil {
			return nil, err
		}

		token, err := jwt.Parse([]byte(stoken))
		if err != nil {
			return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token: %v", err.Error()))
		}

		context.WithValue(ctx, TokenContextKey, token)
	}

	if len(jwkSets) == 0 {
		return nil, errors.New("no jwk sets provided. Cannot de auth without auth providers")
	}

	stoken, err := tokenFromMetadata(ctx)
	if err != nil {
		return nil, err
	}

	var token jwt.Token
	var parseError error
	var validateError error
	for issuer, jwkSet := range jwkSets {
		token, parseError = jwt.Parse([]byte(stoken), jwt.WithKeySet(jwkSet))
		if parseError != nil {
			continue
		}

		validateError = jwt.Validate(token, jwt.WithIssuer(issuer))
		if validateError != nil {
			continue
		}

		break
	}

	if parseError != nil {
		return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token: %v", parseError.Error()))
	}
	if validateError != nil {
		return nil, status.Error(codes.Unauthenticated, fmt.Sprintf("invalid token (issuer): %v", validateError.Error()))
	}

	return context.WithValue(ctx, TokenContextKey, token), nil
}

func AuthUnaryInterceptor(jwkSets map[string]jwk.Set) (grpc.UnaryServerInterceptor, error) {
	if !SkipJwtVerification && len(jwkSets) == 0 {
		return nil, errors.New("no jwk sets provided. Cannot de auth without auth providers")
	}
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp any, err error) {
		authCtx, err := authenticateContext(ctx, jwkSets)
		if err != nil {
			return nil, status.Error(codes.Internal, err.Error())
		}
		return handler(authCtx, req)
	}, nil
}

func AuthStreamInterceptor(jwkSets map[string]jwk.Set) (grpc.StreamServerInterceptor, error) {
	if !SkipJwtVerification && len(jwkSets) == 0 {
		return nil, errors.New("no jwk sets provided. Cannot de auth without auth providers")
	}
	return func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		authCtx, err := authenticateContext(stream.Context(), jwkSets)
		if err != nil {
			return status.Error(codes.Internal, err.Error())
		}
		stream = authenticateServerStream(stream, authCtx)
		return handler(srv, stream)
	}, nil
}

type authenticatedServerStream struct {
	grpc.ServerStream
	AuthenticatedContext context.Context
}

func (s *authenticatedServerStream) Context() context.Context {
	return s.AuthenticatedContext
}

func authenticateServerStream(stream grpc.ServerStream, ctx context.Context) *authenticatedServerStream {
	if existing, ok := stream.(*authenticatedServerStream); ok {
		return existing
	}
	return &authenticatedServerStream{
		ServerStream:         stream,
		AuthenticatedContext: ctx,
	}
}

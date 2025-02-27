package auth

import (
	"log/slog"
)

type AuthorizerServer struct {
	logger *slog.Logger
}

func NewAuthorizerServer(logger *slog.Logger) *AuthorizerServer {
	return &AuthorizerServer{
		logger: logger,
	}
}

func (server *AuthorizerServer) RegisterRoutes() {
}

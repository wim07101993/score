package auth

import (
	"github.com/markbates/goth/gothic"
	"log/slog"
	"net/http"
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
	http.HandleFunc("/auth/google", server.signInWithProvider)
	http.HandleFunc("/auth/google/callback", server.authCallback)
	http.HandleFunc("/logout/google", server.logout)
}

func (server *AuthorizerServer) signInWithProvider(res http.ResponseWriter, req *http.Request) {
	gothic.BeginAuthHandler(res, req)
}

func (server *AuthorizerServer) authCallback(res http.ResponseWriter, req *http.Request) {
	_, err := gothic.CompleteUserAuth(res, req)
	if err != nil {
		server.logger.Error("failed to complete user auth", slog.Any("error", err))
		res.WriteHeader(http.StatusInternalServerError)
		return
	}
	res.WriteHeader(http.StatusOK)
}

func (server *AuthorizerServer) logout(res http.ResponseWriter, req *http.Request) {
	err := gothic.Logout(res, req)
	if err != nil {
		server.logger.Error("failed to logout", slog.Any("error", err))
	}
}

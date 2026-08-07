package auth

import (
	"context"
	"score/internal"
	"score/internal/api"
	"score/internal/oidc"
)

const (
	RoleScoreEditor = "score_editor"
	RoleScoreViewer = "score_viewer"
)

type OidcClient interface {
	IntrospectToken(ctx context.Context, token string) (bool, error)
	GetUserInfo(ctx context.Context, token string) (*oidc.UserInfo, error)
}

type SecurityHandler struct {
	Oidc OidcClient
}

var _ api.SecurityHandler = (*SecurityHandler)(nil)

func NewSecurityHandler(oidcClient OidcClient) *SecurityHandler {
	return &SecurityHandler{Oidc: oidcClient}
}

func (h *SecurityHandler) HandleOAuth2(
	ctx context.Context,
	operationName api.OperationName,
	t api.OAuth2) (context.Context, error) {
	if t.Token == "" {
		return ctx, ErrMalformedAuthorization
	}

	isValid, err := h.Oidc.IntrospectToken(ctx, t.Token)
	if err != nil {
		return ctx, ErrIntrospectionFailed.WithParent(err)
	}
	if !isValid {
		return ctx, ErrTokenNotValid
	}

	user, err := h.Oidc.GetUserInfo(ctx, t.Token)
	if err != nil {
		return ctx, ErrUserInfoFailed.WithParent(err)
	}

	for _, role := range t.Scopes {
		if _, ok := user.Roles[role]; !ok {
			return ctx, ErrMissingRole.WithAdditionalData("required_role", role)
		}
	}

	return context.WithValue(ctx, internal.UserInfoKey, user), nil
}

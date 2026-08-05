// Package auth decides who may do what.
//
// Talking to the identity provider is not its job: that lives in
// score/internal/oidc, and this package only asks it what it needs to make the
// decision.
package auth

import (
	"context"
	"fmt"
	"net/http"
	"score/internal"
	"score/internal/api"
	"score/internal/httperror"
	"score/internal/oidc"
)

const (
	RoleScoreEditor = "score_editor"
	RoleScoreViewer = "score_viewer"
)

// SecurityHandler answers the one question the generated server asks about
// every request: may this token do this?
//
// Which roles an operation needs is not decided here — it is written down in
// the openapi document, next to the operation, and handed to us by the
// generated server.
type SecurityHandler struct {
	Oidc *oidc.Client
}

var _ api.SecurityHandler = (*SecurityHandler)(nil)

func NewSecurityHandler(oidcClient *oidc.Client) *SecurityHandler {
	return &SecurityHandler{Oidc: oidcClient}
}

// HandleOAuth2 introspects the token, looks up who it belongs to, and checks
// that they hold every role the operation asks for.
//
// The roles arrive as the scopes of the operation's security requirement, which
// is where api/endpoints writes them down.
//
// A request without an authorization header, or with one that is not a bearer
// scheme, never reaches this: the generated server turns those away itself.
func (h *SecurityHandler) HandleOAuth2(
	ctx context.Context,
	operationName api.OperationName,
	t api.OAuth2) (context.Context, error) {
	if t.Token == "" {
		return ctx, httperror.New(http.StatusUnauthorized,
			api.ProblemDetailsErrorCodeInvalidCredentials,
			"authorization header is malformed. Expected 'Bearer {token}'")
	}

	isValid, err := h.Oidc.IntrospectToken(ctx, t.Token)
	if err != nil {
		return ctx, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to introspect token")
	}
	if !isValid {
		return ctx, httperror.New(http.StatusUnauthorized,
			api.ProblemDetailsErrorCodeInvalidCredentials, "token not valid")
	}

	user, err := h.Oidc.GetUserInfo(ctx, t.Token)
	if err != nil {
		return ctx, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get user info")
	}

	for _, role := range t.Scopes {
		if _, ok := user.Roles[role]; !ok {
			return ctx, httperror.New(http.StatusForbidden,
				api.ProblemDetailsErrorCodeMissingRole,
				fmt.Sprintf("user does not have required role to perform this action (required role: %s)", role))
		}
	}

	return context.WithValue(ctx, internal.UserInfoKey, user), nil
}

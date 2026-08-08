package auth

import (
	"net/http"

	"score/internal/api"
)

var (
	ErrMalformedAuthorization = api.NewProblemDetailsError(
		http.StatusUnauthorized,
		api.ProblemDetailsErrorCodeInvalidCredentials,
		"authorization header is malformed. Expected 'Bearer {token}'",
	)
	ErrTokenNotValid = api.NewProblemDetailsError(
		http.StatusUnauthorized,
		api.ProblemDetailsErrorCodeInvalidCredentials,
		"token not valid",
	)
	ErrMissingRole = api.NewProblemDetailsError(
		http.StatusForbidden,
		api.ProblemDetailsErrorCodeMissingRole,
		"user does not have the role required to perform this action",
	)
	ErrIntrospectionFailed = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to introspect token",
	)
	ErrUserInfoFailed = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to get user info",
	)
)

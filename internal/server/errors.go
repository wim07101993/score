package server

import (
	"net/http"

	"score/internal/api"
)

var (
	ErrUnsupportedMediaType = api.NewProblemDetailsError(
		http.StatusUnsupportedMediaType,
		api.ProblemDetailsErrorCodeUnsupportedMediaType,
		"content-type not supported",
	)
	ErrEndpointNotFound = api.NewProblemDetailsError(
		http.StatusNotFound,
		api.ProblemDetailsErrorCodeEndpointNotFound,
		"no such endpoint",
	)
	ErrMethodNotAllowed = api.NewProblemDetailsError(
		http.StatusMethodNotAllowed,
		api.ProblemDetailsErrorCodeMethodNotAllowed,
		"method not allowed on this endpoint",
	)

	ErrScoreNotFound = api.NewProblemDetailsError(
		http.StatusNotFound,
		api.ProblemDetailsErrorCodeScoreNotFound,
		"no score found with the given id",
	)
	ErrInvalidMusicXml = api.NewProblemDetailsError(
		http.StatusBadRequest,
		api.ProblemDetailsErrorCodeInvalidMusicXML,
		"invalid music xml",
	)
	ErrRequestBodyTooLarge = api.NewProblemDetailsError(
		http.StatusRequestEntityTooLarge,
		api.ProblemDetailsErrorCodeRequestBodyTooLarge,
		"request body is larger than this server reads",
	)

	ErrSetNotFound = api.NewProblemDetailsError(
		http.StatusNotFound,
		api.ProblemDetailsErrorCodeSetNotFound,
		"no set found with the given id",
	)
	// ErrSetEntryNotFound is the answer to writing a view of an entry that is
	// not there, is not in the set that was named, or is in a set the caller
	// cannot read. Telling those apart would answer questions about other
	// people's sets.
	ErrSetEntryNotFound = api.NewProblemDetailsError(
		http.StatusNotFound,
		api.ProblemDetailsErrorCodeSetEntryNotFound,
		"no entry found with the given id in the given set",
	)
	// ErrNotSetOwner is only ever the answer to writing a set that is shared
	// with the caller. Reading one they may not see at all is ErrSetNotFound:
	// saying "not yours" about a set would say that it exists.
	ErrNotSetOwner = api.NewProblemDetailsError(
		http.StatusForbidden,
		api.ProblemDetailsErrorCodeNotSetOwner,
		"only the owner of a set can change it",
	)
	ErrInvalidSet = api.NewProblemDetailsError(
		http.StatusBadRequest,
		api.ProblemDetailsErrorCodeInvalidSet,
		"invalid set",
	)
	ErrInvalidSetEntry = api.NewProblemDetailsError(
		http.StatusBadRequest,
		api.ProblemDetailsErrorCodeInvalidSetEntry,
		"invalid set entry",
	)
	ErrUnknownScore = api.NewProblemDetailsError(
		http.StatusBadRequest,
		api.ProblemDetailsErrorCodeUnknownScore,
		"the set names a score that does not exist",
	)

	ErrReadRequestBody = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to read request body",
	)
	ErrGetScore = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to get score",
	)
	ErrSaveScore = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to save score",
	)
	ErrListScores = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to get scores page",
	)
	ErrGetSet = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to get set",
	)
	ErrSaveSet = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to save set",
	)
	ErrDeleteSet = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to delete set",
	)
	ErrListSets = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to get sets page",
	)
	ErrSaveSetEntry = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to save the entry of a set",
	)
	ErrDeleteSetEntry = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to delete the entry of a set",
	)
	ErrSaveSetEntryView = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"failed to save the view of a set entry",
	)
	// ErrNoUserInfo is a request that got past the security handler without a
	// caller on it. Nothing should be able to arrange that, so it is a fault
	// here rather than anything the caller can act on.
	ErrNoUserInfo = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"no user info on an authenticated request",
	)

	ErrUnknown = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"an unknown error occurred",
	)
)

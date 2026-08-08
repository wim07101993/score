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
	ErrUnknown = api.NewProblemDetailsError(
		http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError,
		"an unknown error occurred",
	)
)

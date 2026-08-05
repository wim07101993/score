// Package httperror carries the answer a failure deserves: the status code the
// caller is given, the code an application branches on, and the message a human
// reads.
//
// The generated API server funnels every failure — the ones ogen raises while
// it reads a request, and the ones the handlers return — through a single
// place. This is what that place needs to turn an error into the problem
// details described in api/schemas/problem_details.yaml.
package httperror

import (
	"errors"
	"fmt"
	"net/http"

	"score/internal/api"

	"github.com/ogen-go/ogen/ogenerrors"
)

// Error is a failure that knows what to tell the caller about itself.
type Error struct {
	// Status is the http status code to answer with.
	Status int
	// Code is which kind of failure this is, as the caller is allowed to know
	// it. The set it comes from is named in api/schemas/problem_details.yaml,
	// which is why this is the generated type rather than a string: a code the
	// document does not promise cannot be written down here.
	Code api.ProblemDetailsErrorCode
	// Message is what the caller is told. It may not give away anything the
	// caller is not allowed to know.
	Message string
	// Cause is the failure underneath, for the log.
	Cause error
}

// New describes a failure of the caller's own making.
func New(status int, code api.ProblemDetailsErrorCode, message string) *Error {
	return &Error{Status: status, Code: code, Message: message}
}

// Wrap gives an existing failure the answer it deserves.
func Wrap(cause error, status int, code api.ProblemDetailsErrorCode, message string) *Error {
	return &Error{Status: status, Code: code, Message: message, Cause: cause}
}

func (err *Error) Error() string {
	if err.Cause == nil {
		return err.Message
	}
	return fmt.Sprintf("%s: %s", err.Message, err.Cause)
}

func (err *Error) Unwrap() error {
	return err.Cause
}

// Answer is what to respond to the caller about the given error.
//
// A failure of the server itself is answered without its detail: what went
// wrong inside belongs in the log, not in the response.
func Answer(err error) (status int, code api.ProblemDetailsErrorCode, message string) {
	var httpErr *Error
	if errors.As(err, &httpErr) {
		return httpErr.Status, httpErr.Code, httpErr.Message
	}

	// Whatever the generated server rejected on its own — a parameter that does
	// not parse, a body in a media type the operation does not read — already
	// knows which status code it is, but not what this API calls that kind of
	// failure. That is read back out of the status code.
	status = ogenerrors.ErrorCode(err)
	if status >= http.StatusInternalServerError {
		return status, api.ProblemDetailsErrorCodeInternalError, "the server failed to handle the request"
	}
	return status, codeOf(status), err.Error()
}

// codeOf is the kind of failure a status code amounts to, for the failures that
// were turned down before any handler had an opinion about them.
func codeOf(status int) api.ProblemDetailsErrorCode {
	switch status {
	case http.StatusUnauthorized:
		return api.ProblemDetailsErrorCodeInvalidCredentials
	case http.StatusForbidden:
		return api.ProblemDetailsErrorCodeMissingRole
	case http.StatusNotFound:
		return api.ProblemDetailsErrorCodeEndpointNotFound
	case http.StatusMethodNotAllowed:
		return api.ProblemDetailsErrorCodeMethodNotAllowed
	case http.StatusUnsupportedMediaType:
		return api.ProblemDetailsErrorCodeUnsupportedMediaType
	default:
		return api.ProblemDetailsErrorCodeInvalidRequest
	}
}

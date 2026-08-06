// Package failure says what went wrong, in the terms of this application
// rather than of any technology it happens to be built on.
//
// A Failure names what sort of failure it is with a Code, carries a Message the
// caller may be shown, and keeps the error underneath for the log. The codes
// are deliberately few and deliberately plain: they say what happened, not how
// the answer is transported or where the data was kept. Nothing here knows that
// this application is served over http or stored in postgres, and nothing here
// should be taught to.
//
// That means the vocabulary stops where a technology begins. A route that does
// not exist, a method an endpoint does not answer, a body in a media type that
// cannot be read — those are facts about http, and they are said in http's own
// terms, as the problem details of api/schemas/problem_details.yaml. A row that
// will not scan or a constraint that was violated is a fact about the store,
// and stays behind the package that owns it. What crosses a layer boundary is
// one of the codes below.
package failure

import (
	"fmt"
	"log/slog"

	"github.com/go-faster/errors"
)

// The codes a failure can carry. The set is closed, and every member of it is
// something that would still be true if this application were spoken to over
// something other than http: the API layer knows what each one is worth as an
// answer, and that is the only place that decision is made.
const (
	// CodeInternal is a failure of the application itself. Nothing the caller
	// did caused it, and nothing they do will avoid it.
	CodeInternal = "internal"
	// CodeInvalidInput is something the application understood well enough to
	// know it will not act on it.
	CodeInvalidInput = "invalid_input"
	// CodeUnauthenticated is a caller whose identity could not be established.
	CodeUnauthenticated = "unauthenticated"
	// CodePermissionDenied is a caller who is known, and is not allowed to do
	// this.
	CodePermissionDenied = "permission_denied"
)

type Failure struct {
	Code    string
	Message string
	Details any
	Parent  error
}

func NewFailure(code string, message string, details any, cause error) Failure {
	return Failure{
		Code:    code,
		Message: message,
		Details: details,
		Parent:  cause,
	}
}

func (f Failure) Error() string {
	return fmt.Sprintf("%s: %s", f.Code, f.Message)
}

func (f Failure) Unwrap() error {
	return f.Parent
}

func (f Failure) Is(target error) bool {
	var t Failure
	if !errors.As(target, &t) {
		return false
	}
	if f.Code != t.Code {
		return false
	}
	if t.Parent != nil {
		return errors.Is(f.Parent, t.Parent)
	}
	return true
}

func (f Failure) LogValue() slog.Value {
	attrs := []slog.Attr{
		slog.String("code", f.Code),
		slog.String("message", f.Message),
	}
	if f.Parent != nil {
		attrs = append(attrs, slog.Any("parent", f.Parent))
	}
	return slog.GroupValue(attrs...)
}

func (f Failure) WithMessage(message string) Failure {
	f.Message = message
	return f
}

func (f Failure) WithParent(cause error) Failure {
	f.Parent = cause
	return f
}

func (f Failure) WithDetails(details any) Failure {
	f.Details = details
	return f
}

// One constructor per code, so that the code and the kind of failure it stands
// for cannot drift apart at the call site. Pass a nil parent when there is no
// failure underneath this one.

// Internal is a failure of the application itself.
func Internal(message string, parent error) Failure {
	return Failure{Code: CodeInternal, Message: message, Parent: parent}
}

// InvalidInput is something the application will not act on.
func InvalidInput(message string, parent error) Failure {
	return Failure{Code: CodeInvalidInput, Message: message, Parent: parent}
}

// Unauthenticated is a caller whose identity could not be established.
func Unauthenticated(message string, parent error) Failure {
	return Failure{Code: CodeUnauthenticated, Message: message, Parent: parent}
}

// PermissionDenied is a caller who is known, and is not allowed to do this.
func PermissionDenied(message string, parent error) Failure {
	return Failure{Code: CodePermissionDenied, Message: message, Parent: parent}
}

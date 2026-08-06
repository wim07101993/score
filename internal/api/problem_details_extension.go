package api

import (
	"errors"
	"fmt"
	"log/slog"
	"net/http"
)

// NewProblemDetails is a failure that is about http itself: a route that does
// not exist, a method an endpoint does not answer, a body in a media type it
// cannot read. These have no meaning below this layer, so they are not said in
// the application's own vocabulary — they are said here, in the one the caller
// is answered in.
//
// It is an error, so an operation can return one where it would return any
// other, and the error handler passes it through untouched.
func NewProblemDetails(status int, errorCode ProblemDetailsErrorCode, detail string) ProblemDetails {
	return ProblemDetails{
		// Every failure this server answers is about:blank, RFC 9457's way of
		// saying a problem is its status code and nothing more. What tells them
		// apart is the errorCode.
		Type: "about:blank",
		// The title summarises the kind of problem and reads the same for every
		// occurrence of it; what happened this particular time is the detail.
		Title:     http.StatusText(status),
		Status:    status,
		Detail:    detail,
		ErrorCode: errorCode,
	}
}

func (pd ProblemDetails) Error() string {
	return fmt.Sprintf("%s: %s", pd.ErrorCode, pd.Title)
}

func (pd ProblemDetails) Is(target error) bool {
	var t ProblemDetails
	if !errors.As(target, &t) {
		return false
	}
	if pd.ErrorCode != t.ErrorCode {
		return false
	}
	return true
}

func (pd ProblemDetails) LogValue() slog.Value {
	var attrs []slog.Attr
	if pd.Type != "" {
		attrs = append(attrs, slog.String("type", pd.Type))
	}
	if pd.Title != "" {
		attrs = append(attrs, slog.String("title", pd.Title))
	}
	if pd.Status != 0 {
		attrs = append(attrs, slog.Int("status", pd.Status))
	}
	if pd.Detail != "" {
		attrs = append(attrs, slog.String("detail", pd.Detail))
	}
	if pd.Instance != "" {
		attrs = append(attrs, slog.String("instance", pd.Instance))
	}
	if pd.ErrorCode != "" {
		attrs = append(attrs, slog.String("error_code", string(pd.ErrorCode)))
	}
	if len(pd.AdditionalProps) > 0 {
		attrs = append(attrs, slog.Any("additional_properties", pd.AdditionalProps))
	}
	return slog.GroupValue(attrs...)
}

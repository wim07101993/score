package failure

import (
	"fmt"
	"log/slog"

	"github.com/go-faster/errors"
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

func Internal(message string, parent error) Failure {
	return Failure{
		Message: message,
		Parent:  parent,
	}
}

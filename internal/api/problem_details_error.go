package api

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"sync/atomic"

	slogctx "github.com/veqryn/slog-context"
)

// FullErrorInResponse attaches the unwrapped cause of an error to the response
// body under `parent`. It is a **test-only** aid: it turns an opaque "an
// unexpected error occurred" into the chain that produced it, which is what
// makes a red integration run diagnosable. Never enable it on a served
// instance — the chain carries internals (SQL, validation paths, wrapped
// library errors) that the client has no business seeing, which is why nothing
// of the parent reaches the response while it is off.
var FullErrorInResponse = atomic.Bool{}

type ProblemDetailsError struct {
	Type           string
	Title          string
	Status         int
	Detail         string
	Instance       string
	ErrorCode      ProblemDetailsErrorCode
	Parent         error
	AdditionalData map[string]any
}

func NewProblemDetailsError(status int, errorCode ProblemDetailsErrorCode, detail string) ProblemDetailsError {
	return ProblemDetailsError{
		Type:      "about:blank",
		Title:     http.StatusText(status),
		Status:    status,
		Detail:    detail,
		ErrorCode: errorCode,
	}
}

func (pd ProblemDetailsError) Log(ctx context.Context) {
	if pd.Status >= http.StatusInternalServerError {
		slogctx.Error(ctx, "failed to handle http request", slogctx.Err(pd))
	} else {
		slogctx.Info(ctx, "refused http request", slogctx.Err(pd))
	}
}

func (pd ProblemDetailsError) Error() string {
	return fmt.Sprintf("%s: %s", pd.ErrorCode, pd.Title)
}

func (pd ProblemDetailsError) Unwrap() error {
	return pd.Parent
}

func (pd ProblemDetailsError) Is(target error) bool {
	var t ProblemDetailsError
	if !errors.As(target, &t) {
		return false
	}
	if pd.ErrorCode != t.ErrorCode {
		return false
	}
	return true
}

func (pd ProblemDetailsError) WithParent(err error) ProblemDetailsError {
	pd.Parent = err
	return pd
}

func (pd ProblemDetailsError) WithAdditionalData(key string, value any) ProblemDetailsError {
	if pd.AdditionalData == nil {
		pd.AdditionalData = make(map[string]any)
	}
	pd.AdditionalData[key] = value
	return pd
}

func (pd ProblemDetailsError) LogValue() slog.Value {
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
	if pd.Parent != nil {
		attrs = append(attrs, slog.Any("parent", pd.Parent))
	}
	return slog.GroupValue(attrs...)
}

func (pd ProblemDetailsError) ProblemDetails(ctx context.Context) ProblemDetails {
	additionalProps := make(ProblemDetailsAdditional)

	if len(pd.AdditionalData) > 0 {
		for key, val := range pd.AdditionalData {
			jsonValue, err := json.Marshal(val)
			if err != nil {
				slogctx.Error(ctx, "failed to marshal full additional data", slogctx.Err(err))
				continue
			}
			additionalProps[key] = jsonValue
		}
	}

	if FullErrorInResponse.Load() && pd.Parent != nil {
		jsonParent, err := json.Marshal(createFullErrDetailsDetailsMap(pd.Parent))
		if err != nil {
			slogctx.Error(ctx, "failed to marshal parent", slogctx.Err(err))
		} else {
			additionalProps["parent"] = jsonParent
		}
	}

	return ProblemDetails{
		Type:            pd.Type,
		Title:           pd.Title,
		Status:          pd.Status,
		Detail:          pd.Detail,
		Instance:        pd.Instance,
		ErrorCode:       pd.ErrorCode,
		AdditionalProps: additionalProps,
	}
}

func createFullErrDetailsDetailsMap(err error) any {
	if err == nil {
		return nil
	}

	errmap := make(map[string]any)
	errmap["message"] = err.Error()
	errmap["type"] = fmt.Sprintf("%T", err)

	parent := errors.Unwrap(err)
	if parent != nil {
		errmap["parent"] = createFullErrDetailsDetailsMap(parent)
	}

	return errmap
}

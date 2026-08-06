package server

import (
	"context"
	"fmt"
	"net/http"
	"score/internal/api"
	"score/internal/failure"
	"sync/atomic"

	"github.com/go-faster/errors"
	"github.com/ogen-go/ogen/ogenerrors"
	slogctx "github.com/veqryn/slog-context"
)

// FullErrorInResponse attaches the unwrapped cause of an error to the response
// body under `details.parent`. It is a **test-only** aid: it turns an opaque
// "an unexpected error occurred" into the chain that produced it, which is what
// makes a red integration run diagnosable. Never enable it on a served
// instance — the chain carries internals (SQL, validation paths, wrapped
// library errors) that the client has no business seeing.
var FullErrorInResponse = atomic.Bool{}

func ErrorHandler(ctx context.Context, w http.ResponseWriter, _ *http.Request, err error) {
	problemDetails := errToProblemDetails(ctx, err)

	if FullErrorInResponse.Load() {
		if errmap := createFullErrDetailsDetailsMap(err); errmap != nil {
			if problemDetails.AdditionalProps == nil {
				problemDetails.AdditionalProps = make(api.ProblemDetailsAdditional)
			}
			if err := api.AddToAdditionalProperties(problemDetails.AdditionalProps, "err", errmap); err != nil {
				slogctx.Error(ctx, "failed to marshal full error", slogctx.Err(err))
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(problemDetails.Status)
	data, err := problemDetails.MarshalJSON()
	if err != nil {
		slogctx.Error(ctx, "failed to marshal error response", slogctx.Err(err))
	}
	_, _ = w.Write(data)
}

func errToProblemDetails(ctx context.Context, err error) api.ProblemDetails {
	var problemDetails api.ProblemDetails
	problemDetails.SetType("about:blank")

	if errors.As(err, &problemDetails) {
		return problemDetails
	}

	if errors.Is(err, &ogenerrors.SecurityError{}) {
		problemDetails.SetStatus(http.StatusUnauthorized)
		problemDetails.SetErrorCode(api.ProblemDetailsErrorCodeMissingRole)
		problemDetails.SetTitle("You are not authorized to perform this request")
		problemDetails.SetDetail(err.Error())
		return problemDetails
	}

	if errors.Is(err, &ogenerrors.DecodeParamsError{}) || errors.Is(err, &ogenerrors.DecodeRequestError{}) {
		problemDetails.SetStatus(http.StatusBadRequest)
		problemDetails.SetErrorCode("invalid_request")
		problemDetails.SetTitle("The request was invalid")
		problemDetails.SetDetail(err.Error())
		return problemDetails
	}

	var f failure.Failure
	if errors.As(err, &f) {
		problemDetails.SetErrorCode(api.ProblemDetailsErrorCode(f.Code))
		problemDetails.SetTitle(f.Message)
		problemDetails.SetDetail(f.Error())
		if f.Details != nil {
			problemDetails.AdditionalProps = make(api.ProblemDetailsAdditional)
			if err := api.AddToAdditionalProperties(problemDetails.AdditionalProps, "details", f.Details); err != nil {
				slogctx.Error(ctx, "failed to marshal details", slogctx.Err(err))
			}
		}

		return problemDetails
	}

	problemDetails.SetStatus(http.StatusInternalServerError)
	problemDetails.SetTitle("An unexpected error happened")
	problemDetails.SetDetail(err.Error())

	return problemDetails
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

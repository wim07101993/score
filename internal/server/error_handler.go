package server

import (
	"context"
	"fmt"
	"log/slog"
	"mime"
	"net/http"
	"score/internal/api"
	"score/internal/failure"
	"score/internal/logging"
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

// ErrorHandler answers the failures the generated server runs into before any
// operation gets a say: a token it would not accept, a parameter that does not
// parse, a body it cannot read.
func ErrorHandler(ctx context.Context, w http.ResponseWriter, req *http.Request, err error) {
	// A request that does not say what it carries is one the server cannot
	// read, whatever the generated server made of it.
	if isUnreadableMediaType(req) {
		err = api.NewProblemDetails(http.StatusUnsupportedMediaType,
			api.ProblemDetailsErrorCodeUnsupportedMediaType, "content-type not supported")
	}
	writeProblemDetails(ctx, w, err)
}

// NewError answers the failures the operations return. It goes through the
// same mapping as ErrorHandler, so that what a caller is told does not depend
// on how far into the request the failure happened.
func (h *Handler) NewError(ctx context.Context, err error) *api.XxxUnknownErrorStatusCode {
	problemDetails := errToProblemDetails(ctx, err)
	withFullError(ctx, &problemDetails, err)
	logFailure(ctx, problemDetails.Status, err)

	return &api.XxxUnknownErrorStatusCode{
		StatusCode: problemDetails.Status,
		Response:   problemDetails,
	}
}

// NotFound answers a request for something this application does not offer, in
// the same shape as every other failure.
func NotFound(w http.ResponseWriter, req *http.Request) {
	writeProblemDetails(req.Context(), w,
		api.NewProblemDetails(http.StatusNotFound,
			api.ProblemDetailsErrorCodeEndpointNotFound, "no such endpoint"))
}

// MethodNotAllowed answers a request for something this application does offer,
// but not in the way it was asked for.
func MethodNotAllowed(w http.ResponseWriter, req *http.Request, allowed string) {
	w.Header().Set("Allow", allowed)
	writeProblemDetails(req.Context(), w,
		api.NewProblemDetails(http.StatusMethodNotAllowed,
			api.ProblemDetailsErrorCodeMethodNotAllowed, "method not allowed on this endpoint"))
}

// writeProblemDetails is the one place a failure becomes bytes on the wire, for
// every failure the generated server does not encode for us itself.
func writeProblemDetails(ctx context.Context, w http.ResponseWriter, err error) {
	problemDetails := errToProblemDetails(ctx, err)
	withFullError(ctx, &problemDetails, err)
	logFailure(ctx, problemDetails.Status, err)

	// Marshalled before anything is written, so that a body that cannot be
	// built does not leave a status code already committed to.
	data, marshalErr := problemDetails.MarshalJSON()
	if marshalErr != nil {
		slogctx.Error(ctx, "failed to marshal error response", slogctx.Err(marshalErr))
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(problemDetails.Status)
	_, _ = w.Write(data)
}

// withFullError attaches the chain that produced a failure, when the aid is
// switched on. See FullErrorInResponse.
func withFullError(ctx context.Context, problemDetails *api.ProblemDetails, err error) {
	if !FullErrorInResponse.Load() {
		return
	}
	errmap := createFullErrDetailsDetailsMap(err)
	if errmap == nil {
		return
	}
	if problemDetails.AdditionalProps == nil {
		problemDetails.AdditionalProps = make(api.ProblemDetailsAdditional)
	}
	if err := api.AddToAdditionalProperties(problemDetails.AdditionalProps, "err", errmap); err != nil {
		slogctx.Error(ctx, "failed to marshal full error", slogctx.Err(err))
	}
}

// logFailure writes what went wrong to the logger of the request it went wrong
// in, which is already saying which request that was.
func logFailure(ctx context.Context, status int, err error) {
	attrs := []any{
		slogctx.Err(err),
		slog.Int("status", status),
	}

	if status >= http.StatusInternalServerError {
		slogctx.Error(ctx, "failed to handle http request", attrs...)
		return
	}
	slogctx.Info(ctx, "refused http request", attrs...)
}

// isUnreadableMediaType tells whether a request failed over the media type it
// was sent in. A request without a Content-Type is one of those: it does not
// say what it carries, so the server cannot read it.
func isUnreadableMediaType(req *http.Request) bool {
	if req == nil || req.Method == http.MethodGet || req.Method == http.MethodHead {
		return false
	}
	_, _, err := mime.ParseMediaType(req.Header.Get("Content-Type"))
	return err != nil
}

// errToProblemDetails is what to answer the caller about the given error, as
// api/schemas/problem_details.yaml describes it.
func errToProblemDetails(ctx context.Context, err error) api.ProblemDetails {
	problemDetails := problemDetailsFor(ctx, err)

	// Every failure this server answers is about:blank, RFC 9457's way of
	// saying a problem is its status code and nothing more. What tells them
	// apart is the errorCode.
	if problemDetails.Type == "" {
		problemDetails.SetType("about:blank")
	}
	// The title summarises the kind of problem and reads the same for every
	// occurrence of it; what happened this particular time is the detail.
	if problemDetails.Title == "" {
		problemDetails.SetTitle(http.StatusText(problemDetails.Status))
	}

	// The id the failure was logged under, so that a caller reporting one can
	// be answered with what actually happened. It is a uuid the server either
	// made up or accepted from the caller, and this is how a uuid is written as
	// a URI.
	if correlationId, ok := logging.CorrelationIdFromContext(ctx); ok {
		problemDetails.SetInstance("urn:uuid:" + correlationId)
	}

	return problemDetails
}

func problemDetailsFor(ctx context.Context, err error) api.ProblemDetails {
	var problemDetails api.ProblemDetails

	if errors.As(err, &problemDetails) {
		return problemDetails
	}

	// A failure the application raised says what sort of failure it is, in its
	// own terms. What that is worth as an answer over http is decided here and
	// nowhere else.
	var f failure.Failure
	if errors.As(err, &f) {
		status, errorCode := answerTo(f.Code)
		problemDetails.SetStatus(status)
		problemDetails.SetErrorCode(errorCode)
		problemDetails.SetDetail(f.Message)
		if f.Details != nil {
			problemDetails.AdditionalProps = make(api.ProblemDetailsAdditional)
			if err := api.AddToAdditionalProperties(problemDetails.AdditionalProps, "details", f.Details); err != nil {
				slogctx.Error(ctx, "failed to marshal details", slogctx.Err(err))
			}
		}

		return problemDetails
	}

	// Whatever the generated server turned down on its own — a token it would
	// not accept, a parameter that does not parse, a body in a media type the
	// operation does not read. It already knows which status code it is, but
	// not what this API calls that kind of failure.
	//
	// It has to be matched with errors.As rather than errors.Is: these carry no
	// Is method, so comparing one against a fresh one of the same type is a
	// pointer comparison that never matches.
	//
	// The status comes from ogenerrors.ErrorCode rather than from Code() on the
	// error itself, because a body in the wrong media type arrives as a decode
	// failure — which says 400 — wrapped around the content type error that
	// makes it a 415. Only ErrorCode looks for that.
	var ogenErr ogenerrors.Error
	if errors.As(err, &ogenErr) {
		status := ogenerrors.ErrorCode(err)
		problemDetails.SetStatus(status)
		problemDetails.SetErrorCode(codeOfStatus(status))
		if status < http.StatusInternalServerError {
			problemDetails.SetDetail(err.Error())
			return problemDetails
		}
	}

	// Anything else is the server's own fault by definition: it is a failure
	// nothing here was written to expect. What went wrong belongs in the log,
	// not in the answer, so the caller is told only that something did.
	problemDetails.SetStatus(http.StatusInternalServerError)
	problemDetails.SetErrorCode(api.ProblemDetailsErrorCodeInternalError)
	problemDetails.SetDetail("the server failed to handle the request")

	return problemDetails
}

// codeOfStatus is the kind of failure a status code amounts to, for the
// failures that were turned down before any operation had an opinion on them.
func codeOfStatus(status int) api.ProblemDetailsErrorCode {
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
	}
	if status >= http.StatusInternalServerError {
		return api.ProblemDetailsErrorCodeInternalError
	}
	return api.ProblemDetailsErrorCodeInvalidRequest
}

// answerTo is what a kind of failure amounts to over http: the status the
// caller is given, and the code they branch on.
//
// This is the whole of the translation between what the application says went
// wrong and what this API says about it. Where the API promises something more
// particular than the vocabulary can express — that it was a score that was not
// found, that it was music-xml that would not parse — the operation says so
// itself, by answering with problem details rather than with a failure.
//
// A code this does not know is answered as a failure of the server, because
// that is what it is: something reported a kind of failure this layer was never
// taught about.
func answerTo(code string) (int, api.ProblemDetailsErrorCode) {
	switch code {
	case failure.CodeInvalidInput:
		return http.StatusBadRequest, api.ProblemDetailsErrorCodeInvalidRequest
	case failure.CodeUnauthenticated:
		return http.StatusUnauthorized, api.ProblemDetailsErrorCodeInvalidCredentials
	case failure.CodePermissionDenied:
		return http.StatusForbidden, api.ProblemDetailsErrorCodeMissingRole
	default:
		return http.StatusInternalServerError, api.ProblemDetailsErrorCodeInternalError
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

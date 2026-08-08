//go:build integration

// The requests in this file never reach an operation. They are turned down
// before one is chosen — by the cors handler, the router, the security handler
// or the error handler — and all of that is hand-written code in
// internal/server and internal/logging.
//
// They go through the raw client rather than the generated one: what is being
// tested is what happens to a request the API does not describe, and a client
// generated from that description will not build one.

package integration_test

import (
	"net/http"
	"strings"
	"testing"

	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMalformedAuthorizationHeadersAreRejected(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	scoreId := uuid.NewString()

	tests := []struct {
		name          string
		authorization string
	}{
		{name: "no authorization header", authorization: ""},
		{name: "wrong scheme", authorization: "Basic dXNlcjpwYXNzd29yZA=="},
		{name: "scheme without a token", authorization: "Bearer"},
		{name: "empty token", authorization: "Bearer "},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			res := client.Do(t, helpers.Request{
				Method:        http.MethodGet,
				Path:          "/scores/" + scoreId,
				Authorization: tt.authorization,
			})

			assert.Equalf(t, http.StatusUnauthorized, res.StatusCode,
				"GET /scores/{id} with %q should be unauthorized: %s", tt.authorization, res.Text())
		})
	}
}

func TestAnUploadToAMalformedIdIsARequestProblem(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")

	res := client.Do(t, helpers.Request{
		Method: http.MethodPut,
		Path:   "/scores/not-a-score-id",
		Token:  idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor),
		Body:   helpers.MusicXmlWithWorkAndMovement,
	})

	assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
		"an upload to an id that is not an id should be refused over the id: %s", res.Text())
	assert.Equal(t, "invalid_request", string(res.DecodeProblem(t).ErrorCode))
}

func TestUploadingRejectsUnsupportedContentTypes(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	token := idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	tests := []struct {
		name        string
		contentType string
	}{
		{name: "no content type", contentType: ""},
		{name: "plain text", contentType: "text/plain"},
		{name: "json", contentType: "application/json"},
		{name: "plain xml", contentType: "application/xml"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			res := client.Do(t, helpers.Request{
				Method:      http.MethodPut,
				Path:        "/scores/" + uuid.NewString(),
				Token:       token,
				ContentType: tt.contentType,
				Body:        helpers.MusicXmlWithWorkAndMovement,
			})

			assert.Equalf(t, http.StatusUnsupportedMediaType, res.StatusCode,
				"content-type %q should be rejected: %s", tt.contentType, res.Text())
		})
	}
}

// TestUploadingRejectsBodiesPastTheLimit guards the bound on what one request
// can make this server hold in memory. A score is read whole before it is
// stored, so without the limit a single upload decides how much memory this
// process uses.
func TestUploadingRejectsBodiesPastTheLimit(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")

	res := client.Do(t, helpers.Request{
		Method:      http.MethodPut,
		Path:        "/scores/" + uuid.NewString(),
		Token:       idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor),
		ContentType: "application/vnd.recordare.musicxml",
		Body:        strings.Repeat("x", int(helpers.MaxRequestBodyBytes)+1),
	})

	assert.Equalf(t, http.StatusRequestEntityTooLarge, res.StatusCode,
		"a body past the limit should be refused: %s", res.Text())
	assert.Equal(t, "request_body_too_large", string(res.DecodeProblem(t).ErrorCode))
}

// TestFetchingAScoreWithAMalformedIdIsARequestProblem checks that a path
// segment that is not an id is answered as a client error rather than as a
// server failure.
func TestFetchingAScoreWithAMalformedIdIsARequestProblem(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")

	res := client.Do(t, helpers.Request{
		Method: http.MethodGet,
		Path:   "/scores/not-a-score-id",
		Token:  helpers.Ensure(t, h.IdentityProvider, "idp").IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor),
	})

	assert.Lessf(t, res.StatusCode, http.StatusInternalServerError,
		"a malformed score id should not be a server error, got %d: %s", res.StatusCode, res.Text())
}

func TestListingScoresRequiresAChangeWindow(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	token := idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	tests := []struct {
		name string
		path string
	}{
		{name: "no parameters", path: "/scores"},
		{name: "only Changes-Since", path: "/scores?Changes-Since=2024-01-01T00:00:00Z"},
		{name: "only Changes-Until", path: "/scores?Changes-Until=2024-01-01T00:00:00Z"},
		{name: "malformed Changes-Since", path: "/scores?Changes-Since=yesterday&Changes-Until=2024-01-01T00:00:00Z"},
		{name: "malformed Changes-Until", path: "/scores?Changes-Since=2024-01-01T00:00:00Z&Changes-Until=tomorrow"},
		{name: "a moment in the old compact format", path: "/scores?Changes-Since=20240101T000000&Changes-Until=20240102T000000"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			res := client.Do(t, helpers.Request{Method: http.MethodGet, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
				"listing scores with %s should be rejected: %s", tt.name, res.Text())
		})
	}
}

func TestUnsupportedMethodsAreRejected(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	token := idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	tests := []struct {
		method string
		path   string
	}{
		{method: http.MethodDelete, path: "/scores/" + uuid.NewString()},
		{method: http.MethodPost, path: "/scores/" + uuid.NewString()},
		{method: http.MethodPost, path: "/scores"},
		{method: http.MethodPut, path: "/scores"},
	}

	for _, tt := range tests {
		t.Run(tt.method+" "+tt.path, func(t *testing.T) {
			t.Parallel()

			res := client.Do(t, helpers.Request{Method: tt.method, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusMethodNotAllowed, res.StatusCode,
				"%s %s should not be allowed: %s", tt.method, tt.path, res.Text())
			assert.NotEmpty(t, res.Headers.Get("Allow"),
				"a refusal over the method should say which ones are allowed")
		})
	}
}

func TestUnknownRoutesReturnNotFound(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")

	res := client.Do(t, helpers.Request{Method: http.MethodGet, Path: "/not-an-endpoint"})

	assert.Equal(t, http.StatusNotFound, res.StatusCode)
}

// TestFailuresAreAnsweredAsProblemDetails checks that a failed request comes
// back in the shape the openapi document promises, whoever turned it down: the
// generated server while it was still reading the request, or a handler that
// refused to serve it.
func TestFailuresAreAnsweredAsProblemDetails(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	token := idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	tests := []struct {
		name      string
		request   helpers.Request
		errorCode string
	}{
		{
			name:      "a score that does not exist",
			request:   helpers.Request{Method: http.MethodGet, Path: "/scores/" + uuid.NewString(), Token: token},
			errorCode: "score_not_found",
		},
		{
			name:      "a score id that is not an id",
			request:   helpers.Request{Method: http.MethodGet, Path: "/scores/not-a-score-id", Token: token},
			errorCode: "invalid_request",
		},
		{
			name:      "a listing without a change window",
			request:   helpers.Request{Method: http.MethodGet, Path: "/scores", Token: token},
			errorCode: "invalid_request",
		},
		{
			name:      "an upload that is not music-xml",
			request:   helpers.Request{Method: http.MethodPut, Path: "/scores/" + uuid.NewString(), Token: token, ContentType: "text/plain", Body: "not a score"},
			errorCode: "unsupported_media_type",
		},
		{
			name:      "an endpoint that does not exist",
			request:   helpers.Request{Method: http.MethodGet, Path: "/not-an-endpoint", Token: token},
			errorCode: "endpoint_not_found",
		},
		{
			name:      "a method the endpoint does not answer",
			request:   helpers.Request{Method: http.MethodDelete, Path: "/scores/" + uuid.NewString(), Token: token},
			errorCode: "method_not_allowed",
		},
		{
			name:      "a request without a token",
			request:   helpers.Request{Method: http.MethodGet, Path: "/scores/" + uuid.NewString()},
			errorCode: "invalid_credentials",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			res := client.Do(t, tt.request)

			require.GreaterOrEqual(t, res.StatusCode, http.StatusBadRequest, "should have failed")
			assert.Equal(t, helpers.ProblemContentType, res.ContentType)

			problem := res.DecodeProblem(t)
			assert.Equal(t, "about:blank", problem.Type, "every failure is about:blank so far")
			assert.Equal(t, http.StatusText(res.StatusCode), problem.Title, "title")
			assert.Equal(t, res.StatusCode, problem.Status,
				"the status in the body should be the status of the response")
			assert.NotEmpty(t, problem.Detail, "a failure should say what went wrong")
			assert.Regexp(t, `^urn:uuid:[0-9a-f-]{36}$`, problem.Instance,
				"a failure should say which occurrence it was")
			assert.Equal(t, tt.errorCode, string(problem.ErrorCode), "the code an application branches on")
		})
	}
}

// TestACorrelationIdThatIsNotAUuidIsNotRepeated guards the one string a caller
// gets to choose that this server writes into its log and back into an answer.
// The header is documented as a plain string, so a caller can send anything;
// what the server may not do is repeat it.
func TestACorrelationIdThatIsNotAUuidIsNotRepeated(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")
	madeUp := "not-a-uuid</script>"

	res := client.Do(t, helpers.Request{
		Method:        http.MethodGet,
		Path:          "/scores/" + uuid.NewString(),
		Token:         helpers.Ensure(t, h.IdentityProvider, "idp").IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor),
		CorrelationId: madeUp,
	})

	require.Equal(t, http.StatusNotFound, res.StatusCode, res.Text())
	instance := res.DecodeProblem(t).Instance
	assert.NotContains(t, instance, madeUp, "a correlation id the caller made up should not be repeated")
	assert.Regexp(t, `^urn:uuid:[0-9a-f-]{36}$`, instance, "one should have been made up instead")
}

func TestPreflightRequestsDoNotRequireAuthentication(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.RawClient, "RawClient")

	res := client.Do(t, helpers.Request{
		Method: http.MethodOptions,
		Path:   "/scores/" + uuid.NewString(),
	})

	assert.Equal(t, http.StatusOK, res.StatusCode, "a preflight request should be answered")
	assert.NotEmpty(t, res.Headers.Get("Access-Control-Allow-Origin"))
	assert.NotEmpty(t, res.Headers.Get("Access-Control-Allow-Methods"))
}

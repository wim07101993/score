package helpers

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"

	"score/internal/api"

	"github.com/stretchr/testify/require"
)

// ProblemContentType is the media type RFC 9457 gives problem details, and the
// one every failure of this API is answered in.
const ProblemContentType = "application/problem+json"

// RawClient sends requests the generated client will not build: a method an
// endpoint does not answer, a path that is not a route, a body with no content
// type, an authorization header that is not a bearer token. Those are turned
// down before any operation is reached, by the cors, logging, routing and error
// handling this server puts in front of them — hand-written code, and the only
// reason this client exists.
//
// It deliberately knows nothing of the API: no routes, no models. A test that
// is about what an operation does should use ApiClient instead.
type RawClient struct {
	baseUrl string
	client  *http.Client
}

type Request struct {
	Method string
	Path   string
	// Token is sent as a bearer token.
	Token string
	// Authorization sets the header verbatim and wins over Token, for tests
	// about malformed authorization headers.
	Authorization string
	// CorrelationId is sent verbatim, including what the generated client
	// would not send.
	CorrelationId string
	Accept        string
	ContentType   string
	Body          string
}

type Response struct {
	StatusCode  int
	ContentType string
	Body        []byte
	Headers     http.Header
}

func (r Response) Text() string { return string(r.Body) }

// DecodeProblem parses a failure response. The API's own type is used to read
// it: what a failure is shaped like is the generated code's business, and what
// this server puts in one is not.
func (r Response) DecodeProblem(t *testing.T) api.ProblemDetails {
	t.Helper()

	var problem api.ProblemDetails
	require.NoErrorf(t, json.Unmarshal(r.Body, &problem),
		"failed to parse problem details response: %s", r.Text())
	return problem
}

func (c *RawClient) Do(t *testing.T, r Request) Response {
	t.Helper()

	var body io.Reader
	if r.Body != "" {
		body = strings.NewReader(r.Body)
	}

	req, err := http.NewRequestWithContext(t.Context(), r.Method, c.baseUrl+r.Path, body)
	require.NoErrorf(t, err, "failed to build the %s %s request", r.Method, r.Path)

	switch {
	case r.Authorization != "":
		req.Header.Set("Authorization", r.Authorization)
	case r.Token != "":
		req.Header.Set("Authorization", "Bearer "+r.Token)
	}
	if r.CorrelationId != "" {
		req.Header.Set("X-Correlation-ID", r.CorrelationId)
	}
	if r.Accept != "" {
		req.Header.Set("Accept", r.Accept)
	}
	if r.ContentType != "" {
		req.Header.Set("Content-Type", r.ContentType)
	}

	res, err := c.client.Do(req)
	require.NoErrorf(t, err, "%s %s failed", r.Method, r.Path)
	defer func() { _ = res.Body.Close() }()

	responseBody, err := io.ReadAll(res.Body)
	require.NoErrorf(t, err, "failed to read the response of %s %s", r.Method, r.Path)

	return Response{
		StatusCode:  res.StatusCode,
		ContentType: res.Header.Get("Content-Type"),
		Body:        responseBody,
		Headers:     res.Header,
	}
}

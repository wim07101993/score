package helpers

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// MusicXmlContentType is the media type the API accepts and returns score
// documents as.
const MusicXmlContentType = "application/vnd.recordare.musicxml"

// MusicXmlContentTypeWithXmlSuffix is the second media type the API accepts for
// the same thing.
const MusicXmlContentTypeWithXmlSuffix = "application/vnd.recordare.musicxml+xml"

// changeWindowLayout is the timestamp format of the Changes-Since and
// Changes-Until query parameters.
const changeWindowLayout = "20060102T150405"

func (h *Harness) EnsureScoresClient(t *testing.T) *ScoresClient {
	t.Helper()
	h.scoresClient.mutex.Lock()
	defer h.scoresClient.mutex.Unlock()

	if h.scoresClient.value == nil {
		h.scoresClient.value = &ScoresClient{
			baseUrl: h.EnsureApiServer(t).URL,
			client:  h.EnsureHttpClient(t),
		}
	}
	return h.scoresClient.value
}

// ScoresClient talks to the score API over HTTP the way a browser would.
type ScoresClient struct {
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
	// CorrelationId ties the request to the log lines and the failure it
	// produces, the way a caller that keeps its own trail would.
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

// DecodeScore parses a score response, failing the test when the body is not
// the JSON the API promises.
func (r Response) DecodeScore(t *testing.T) Score {
	t.Helper()

	var score Score
	require.NoErrorf(t, json.Unmarshal(r.Body, &score), "failed to parse score response: %s", r.Text())
	return score
}

func (r Response) DecodeScores(t *testing.T) []Score {
	t.Helper()

	var scores []Score
	require.NoErrorf(t, json.Unmarshal(r.Body, &scores), "failed to parse scores response: %s", r.Text())
	return scores
}

// Score mirrors the JSON contract the API exposes, so a change to the wire
// format shows up as a test failure rather than as a surprise in the frontend.
type Score struct {
	Id   string `json:"id"`
	Work struct {
		Title  string `json:"title"`
		Number string `json:"number"`
	} `json:"work"`
	Movement struct {
		Title  string `json:"title"`
		Number string `json:"number"`
	} `json:"movement"`
	Creators struct {
		Composers []string `json:"composers"`
		Lyricists []string `json:"lyricists"`
	} `json:"creators"`
	Languages     []string  `json:"languages"`
	Instruments   []string  `json:"instruments"`
	LastChangedAt time.Time `json:"last_changed_at"`
	Tags          []string  `json:"tags"`
}

// DecodeProblem parses a failure response, failing the test when the body is
// not the JSON the API promises.
func (r Response) DecodeProblem(t *testing.T) ProblemDetails {
	t.Helper()

	var problem ProblemDetails
	require.NoErrorf(t, json.Unmarshal(r.Body, &problem),
		"failed to parse problem details response: %s", r.Text())
	return problem
}

// ProblemDetails mirrors what the API answers a failed request with, whichever
// way it failed: RFC 9457 problem details, plus the errorCode this API adds to
// them. Spelled out here rather than reused from the generated code, so that a
// change to the wire format shows up as a test failure.
type ProblemDetails struct {
	Type      string `json:"type"`
	Title     string `json:"title"`
	Status    int    `json:"status"`
	Detail    string `json:"detail"`
	Instance  string `json:"instance"`
	ErrorCode string `json:"errorCode"`
}

// ProblemContentType is the media type RFC 9457 gives problem details, and the
// one every failure of this API is answered in.
const ProblemContentType = "application/problem+json"

func (c *ScoresClient) Do(t *testing.T, r Request) Response {
	t.Helper()

	var body io.Reader
	if r.Body != "" {
		body = strings.NewReader(r.Body)
	}

	req, err := http.NewRequest(r.Method, c.baseUrl+r.Path, body)
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

// PutScore uploads a music-xml document.
func (c *ScoresClient) PutScore(t *testing.T, scoreId string, token string, musicXml string) Response {
	t.Helper()

	return c.Do(t, Request{
		Method:      http.MethodPut,
		Path:        "/scores/" + scoreId,
		Token:       token,
		ContentType: MusicXmlContentType,
		Body:        musicXml,
	})
}

// MustPutScore uploads a document and fails the test unless the API accepted it.
func (c *ScoresClient) MustPutScore(t *testing.T, scoreId string, token string, musicXml string) {
	t.Helper()

	res := c.PutScore(t, scoreId, token, musicXml)
	require.Equalf(t, http.StatusOK, res.StatusCode,
		"failed to upload score %s: %s", scoreId, res.Text())
}

// GetScore fetches the metadata of a single score.
func (c *ScoresClient) GetScore(t *testing.T, scoreId string, token string) Response {
	t.Helper()

	return c.Do(t, Request{
		Method: http.MethodGet,
		Path:   "/scores/" + scoreId,
		Token:  token,
		Accept: "application/json",
	})
}

// GetScoreMusicXml fetches the music-xml document of a single score.
func (c *ScoresClient) GetScoreMusicXml(t *testing.T, scoreId string, token string) Response {
	t.Helper()

	return c.Do(t, Request{
		Method: http.MethodGet,
		Path:   "/scores/" + scoreId,
		Token:  token,
		Accept: MusicXmlContentType,
	})
}

// ListScores fetches every score changed within the given window.
func (c *ScoresClient) ListScores(t *testing.T, token string, since time.Time, until time.Time) Response {
	t.Helper()

	query := url.Values{}
	query.Set("Changes-Since", since.UTC().Format(changeWindowLayout))
	query.Set("Changes-Until", until.UTC().Format(changeWindowLayout))

	return c.Do(t, Request{
		Method: http.MethodGet,
		Path:   "/scores?" + query.Encode(),
		Token:  token,
		Accept: "application/json",
	})
}

func (c *ScoresClient) Healthz(t *testing.T) Response {
	t.Helper()
	return c.Do(t, Request{Method: http.MethodGet, Path: "/healthz"})
}

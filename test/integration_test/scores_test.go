//go:build integration

package integration_test

import (
	"net/http"
	"testing"
	"time"

	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// editorToken is the token most tests upload with.
func editorToken(t *testing.T) string {
	t.Helper()
	return harness.EnsureIdentityProvider(t).
		IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)
}

func aWhileAgo() time.Time { return time.Now().Add(-time.Hour) }
func soon() time.Time      { return time.Now().Add(time.Hour) }

func TestUploadingAScoreReturnsTheSameDocument(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	document := helpers.ExampleMusicXml(t, helpers.ExampleWithWork)
	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, token, document)

	res := client.GetScoreMusicXml(t, scoreId, token)

	require.Equalf(t, http.StatusOK, res.StatusCode, "failed to download the score: %s", res.Text())
	assert.Equal(t, helpers.MusicXmlContentType, res.ContentType)
	assert.Equal(t, document, res.Text(), "the stored document differs from the uploaded one")
}

// TestUploadingAScoreExtractsItsMetadata is the heart of the API: a document
// goes in, and the fields the frontend lists scores by come back out.
func TestUploadingAScoreExtractsItsMetadata(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, token, helpers.MusicXmlWithWorkAndMovement)

	score := client.GetScore(t, scoreId, token).DecodeScore(t)

	assert.Equal(t, scoreId, score.Id)
	assert.Equal(t, "Work title", score.Work.Title, "work title")
	assert.Equal(t, "Work number 41", score.Work.Number, "work number")
	assert.Equal(t, "Movement title", score.Movement.Title, "movement title")
	assert.Equal(t, "Movement number 2", score.Movement.Number, "movement number")
	assert.Equal(t, []string{"Clara Composer"}, score.Creators.Composers, "composers")
	assert.Equal(t, []string{"Larry Lyricist"}, score.Creators.Lyricists, "lyricists")
	assert.Equal(t, []string{"nl"}, score.Languages, "languages")
	assert.Equal(t, []string{"voice.vocals"}, score.Instruments, "instruments")
	assert.NotNil(t, score.Tags, "tags should be an empty list, never null")
	assert.WithinDuration(t, time.Now(), score.LastChangedAt, time.Minute, "last changed at")
}

func TestUploadingAScoreKeepsEveryCreator(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, token, helpers.MusicXmlWithTwoComposers)

	score := client.GetScore(t, scoreId, token).DecodeScore(t)

	assert.Equal(t, []string{"First Composer", "Second Composer"}, score.Creators.Composers)
	assert.Equal(t, []string{"Only Lyricist"}, score.Creators.Lyricists)
}

func TestUploadingRealWorldDocuments(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	tests := []struct {
		name string

		document string

		workTitle     string
		workNumber    string
		movementTitle string
		composers     []string
		lyricists     []string
		instruments   []string
		languages     []string
	}{
		{
			name:        "score with a work element",
			document:    helpers.ExampleWithWork,
			workTitle:   "An die ferne Geliebte (Page 1)",
			workNumber:  "Op. 98",
			composers:   []string{"Ludwig van Beethoven"},
			lyricists:   []string{"Aloys Jeitteles"},
			instruments: []string{"voice.vocals", "keyboard.piano"},
			languages:   []string{"de"},
		},
		{
			// This document has a movement title and no <work> element at all,
			// which MusicXML allows.
			name:          "score without a work element",
			document:      helpers.ExampleWithoutWork,
			movementTitle: "Wie Melodien zieht es mir (Page 1)",
			composers:     []string{"Johannes Brahms"},
			lyricists:     []string{"Klaus Groth"},
			instruments:   []string{"voice.vocals", "keyboard.piano"},
			languages:     []string{"de"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			scoreId := uuid.NewString()
			client.MustPutScore(t, scoreId, token, helpers.ExampleMusicXml(t, tt.document))

			score := client.GetScore(t, scoreId, token).DecodeScore(t)

			assert.Equal(t, tt.workTitle, score.Work.Title, "work title")
			assert.Equal(t, tt.workNumber, score.Work.Number, "work number")
			assert.Equal(t, tt.movementTitle, score.Movement.Title, "movement title")
			assert.Equal(t, tt.composers, score.Creators.Composers, "composers")
			assert.Equal(t, tt.lyricists, score.Creators.Lyricists, "lyricists")
			assert.Equal(t, tt.instruments, score.Instruments, "instruments")
			assert.Equal(t, tt.languages, score.Languages, "languages")
		})
	}
}

func TestUploadingAScoreTwiceReplacesIt(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, token, helpers.MusicXmlWithWorkAndMovement)
	client.MustPutScore(t, scoreId, token, helpers.MusicXmlWithTwoComposers)

	score := client.GetScore(t, scoreId, token).DecodeScore(t)

	assert.Equal(t, "Collaboration", score.Work.Title, "the second upload should have replaced the first")
	assert.Equal(t, 1, harness.CountRows(t, "score_files", scoreId), "score documents")
	assert.Equal(t, 1, harness.CountRows(t, "scores", scoreId), "score metadata rows")

	document := client.GetScoreMusicXml(t, scoreId, token)
	assert.Equal(t, helpers.MusicXmlWithTwoComposers, document.Text())
}

func TestUploadingRejectsDocumentsThatAreNotMusicXml(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	tests := []struct {
		name     string
		document string
	}{
		{name: "another kind of xml", document: helpers.NotMusicXml},
		{name: "malformed xml", document: helpers.MalformedXml},
		{name: "empty body", document: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			scoreId := uuid.NewString()
			res := client.PutScore(t, scoreId, token, tt.document)

			assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
				"uploading %s should be rejected: %s", tt.name, res.Text())
			assert.Zero(t, harness.CountRows(t, "score_files", scoreId),
				"a rejected document should not have been stored")
		})
	}
}

// TestUploadingAnUnknownInstrumentStoresNothing covers a document the parser
// accepts but the database cannot store, because the instrument is not part of
// the instrument enum. Whatever the API answers, it may not leave a document
// behind without the metadata that belongs to it.
func TestUploadingAnUnknownInstrumentStoresNothing(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	scoreId := uuid.NewString()
	res := client.PutScore(t, scoreId, token, helpers.MusicXmlWithUnknownInstrument)

	assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
		"an unsupported instrument is a problem with the uploaded document: %s", res.Text())
	assert.Zero(t, harness.CountRows(t, "score_files", scoreId),
		"a failed upload left the document behind without its metadata")
	assert.Zero(t, harness.CountRows(t, "scores", scoreId), "score metadata rows")
}

func TestUploadingRejectsUnsupportedContentTypes(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

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

func TestUploadingAcceptsBothMusicXmlMediaTypes(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	mediaTypes := []string{
		helpers.MusicXmlContentType,
		helpers.MusicXmlContentTypeWithXmlSuffix,
	}

	for _, mediaType := range mediaTypes {
		t.Run(mediaType, func(t *testing.T) {
			res := client.Do(t, helpers.Request{
				Method:      http.MethodPut,
				Path:        "/scores/" + uuid.NewString(),
				Token:       token,
				ContentType: mediaType,
				Body:        helpers.MusicXmlWithWorkAndMovement,
			})

			assert.Equalf(t, http.StatusOK, res.StatusCode,
				"content-type %q should be accepted: %s", mediaType, res.Text())
		})
	}
}

func TestFetchingAnUnknownScoreReturnsNotFound(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)
	unknownId := uuid.NewString()

	t.Run("metadata", func(t *testing.T) {
		res := client.GetScore(t, unknownId, token)
		assert.Equal(t, http.StatusNotFound, res.StatusCode, res.Text())
	})

	t.Run("document", func(t *testing.T) {
		res := client.GetScoreMusicXml(t, unknownId, token)
		assert.Equal(t, http.StatusNotFound, res.StatusCode, res.Text())
	})
}

// TestFetchingAScoreWithAMalformedIdIsARequestProblem checks that a path
// segment that is not an id is answered as a client error rather than as a
// server failure.
func TestFetchingAScoreWithAMalformedIdIsARequestProblem(t *testing.T) {
	client := harness.EnsureScoresClient(t)

	res := client.GetScore(t, "not-a-score-id", editorToken(t))

	assert.Lessf(t, res.StatusCode, http.StatusInternalServerError,
		"a malformed score id should not be a server error, got %d: %s", res.StatusCode, res.Text())
}

func TestListingScoresRequiresAChangeWindow(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	tests := []struct {
		name string
		path string
	}{
		{name: "no parameters", path: "/scores"},
		{name: "only Changes-Since", path: "/scores?Changes-Since=20240101T000000"},
		{name: "only Changes-Until", path: "/scores?Changes-Until=20240101T000000"},
		{name: "malformed Changes-Since", path: "/scores?Changes-Since=yesterday&Changes-Until=20240101T000000"},
		{name: "malformed Changes-Until", path: "/scores?Changes-Since=20240101T000000&Changes-Until=tomorrow"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			res := client.Do(t, helpers.Request{Method: http.MethodGet, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
				"listing scores with %s should be rejected: %s", tt.name, res.Text())
		})
	}
}

func TestListingScoresReturnsTheScoresInTheWindow(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

	harness.TruncateScores(t)

	first := uuid.NewString()
	second := uuid.NewString()
	client.MustPutScore(t, first, token, helpers.MusicXmlWithWorkAndMovement)
	client.MustPutScore(t, second, token, helpers.MusicXmlWithTwoComposers)

	t.Run("window covering both uploads", func(t *testing.T) {
		res := client.ListScores(t, token, aWhileAgo(), soon())
		require.Equalf(t, http.StatusOK, res.StatusCode, "failed to list scores: %s", res.Text())

		scores := res.DecodeScores(t)
		require.Len(t, scores, 2)

		ids := []string{scores[0].Id, scores[1].Id}
		assert.ElementsMatch(t, []string{first, second}, ids)
	})

	t.Run("window before the uploads", func(t *testing.T) {
		res := client.ListScores(t, token, time.Now().Add(-48*time.Hour), time.Now().Add(-24*time.Hour))
		require.Equalf(t, http.StatusOK, res.StatusCode, "failed to list scores: %s", res.Text())

		assert.Empty(t, res.DecodeScores(t), "scores changed today are not in a window that ended yesterday")
	})
}

func TestUnsupportedMethodsAreRejected(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

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
			res := client.Do(t, helpers.Request{Method: tt.method, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusMethodNotAllowed, res.StatusCode,
				"%s %s should not be allowed: %s", tt.method, tt.path, res.Text())
		})
	}
}

// TestFailuresAreAnsweredAsProblemDetails checks that a failed request comes
// back in the shape the openapi document promises, whoever turned it down: the
// generated server while it was still reading the request, or a handler that
// refused to serve it.
func TestFailuresAreAnsweredAsProblemDetails(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := editorToken(t)

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
			assert.Equal(t, tt.errorCode, problem.ErrorCode, "the code an application branches on")
		})
	}
}

// TestTheCorrelationIdOfAFailureIsTheOneItWasLoggedUnder checks that a caller
// that ties its own requests together gets that same id back as the instance of
// whatever went wrong, so that reporting a failure is enough to find it.
func TestTheCorrelationIdOfAFailureIsTheOneItWasLoggedUnder(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	correlationId := uuid.NewString()

	res := client.Do(t, helpers.Request{
		Method:        http.MethodGet,
		Path:          "/scores/" + uuid.NewString(),
		Token:         editorToken(t),
		CorrelationId: correlationId,
	})

	require.Equal(t, http.StatusNotFound, res.StatusCode, res.Text())
	assert.Equal(t, "urn:uuid:"+correlationId, res.DecodeProblem(t).Instance)
}

// TestACorrelationIdThatIsNotAUuidIsNotRepeated guards the one string a caller
// gets to choose that this server writes into its log and back into an answer.
func TestACorrelationIdThatIsNotAUuidIsNotRepeated(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	madeUp := "not-a-uuid</script>"

	res := client.Do(t, helpers.Request{
		Method:        http.MethodGet,
		Path:          "/scores/" + uuid.NewString(),
		Token:         editorToken(t),
		CorrelationId: madeUp,
	})

	require.Equal(t, http.StatusNotFound, res.StatusCode, res.Text())
	instance := res.DecodeProblem(t).Instance
	assert.NotContains(t, instance, madeUp, "a correlation id the caller made up should not be repeated")
	assert.Regexp(t, `^urn:uuid:[0-9a-f-]{36}$`, instance, "one should have been made up instead")
}

func TestUnknownRoutesReturnNotFound(t *testing.T) {
	client := harness.EnsureScoresClient(t)

	res := client.Do(t, helpers.Request{Method: http.MethodGet, Path: "/not-an-endpoint"})

	assert.Equal(t, http.StatusNotFound, res.StatusCode)
}

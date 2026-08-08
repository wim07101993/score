//go:build integration

package integration_test

import (
	"strings"
	"testing"
	"time"

	"score/internal/api"
	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func aWhileAgo() time.Time { return time.Now().Add(-time.Hour) }
func soon() time.Time      { return time.Now().Add(time.Hour) }

// mustGetScore fetches the metadata of a score the test expects to be there.
func mustGetScore(t *testing.T, client *helpers.ApiClient, scoreId uuid.UUID) *api.Score {
	t.Helper()

	res, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: scoreId})
	require.NoErrorf(t, err, "failed to fetch score %s", scoreId)

	score, ok := res.(*api.Score)
	require.Truef(t, ok, "expected the metadata of score %s, got %#v", scoreId, res)
	return score
}

// mustGetScoreDocument fetches the music-xml of a score the test expects to be
// there, in the media type it asks for.
func mustGetScoreDocument(t *testing.T, client *helpers.ApiClient, scoreId uuid.UUID, mediaType string) string {
	t.Helper()

	res, err := client.GetScore(t.Context(), api.GetScoreParams{
		ScoreId: scoreId,
		Accept:  api.NewOptString(mediaType),
	})
	require.NoErrorf(t, err, "failed to fetch the document of score %s", scoreId)

	switch document := res.(type) {
	case *api.GetScoreOKApplicationVndRecordareMusicxml:
		return helpers.MustReadAll(t, document.Data)
	case *api.GetScoreOKApplicationVndRecordareMusicxmlXML:
		return helpers.MustReadAll(t, document.Data)
	default:
		require.FailNowf(t, "wrong representation",
			"asked for %s and got %#v", mediaType, res)
		return ""
	}
}

func TestUploadingAScoreReturnsTheSameDocument(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	document := helpers.ExampleMusicXml(t, helpers.ExampleWithWork)
	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, document)

	assert.Equal(t, document, mustGetScoreDocument(t, client, scoreId, helpers.MusicXmlContentType),
		"the stored document differs from the uploaded one")
}

// TestUploadingAScoreExtractsItsMetadata is the heart of the API: a document
// goes in, and the fields the frontend lists scores by come back out.
func TestUploadingAScoreExtractsItsMetadata(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithWorkAndMovement)

	score := mustGetScore(t, client, scoreId)

	assert.Equal(t, scoreId, score.ID)
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
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithTwoComposers)

	score := mustGetScore(t, client, scoreId)

	assert.Equal(t, []string{"First Composer", "Second Composer"}, score.Creators.Composers)
	assert.Equal(t, []string{"Only Lyricist"}, score.Creators.Lyricists)
}

func TestUploadingRealWorldDocuments(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

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
			t.Parallel()

			scoreId := uuid.New()
			helpers.MustPutScore(t, client, scoreId, helpers.ExampleMusicXml(t, tt.document))

			score := mustGetScore(t, client, scoreId)

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
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithWorkAndMovement)
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithTwoComposers)

	score := mustGetScore(t, client, scoreId)

	assert.Equal(t, "Collaboration", score.Work.Title, "the second upload should have replaced the first")
	assert.Equal(t, 1, h.CountRows(t, "score_files", scoreId.String()), "score documents")
	assert.Equal(t, 1, h.CountRows(t, "scores", scoreId.String()), "score metadata rows")

	assert.Equal(t, helpers.MusicXmlWithTwoComposers,
		mustGetScoreDocument(t, client, scoreId, helpers.MusicXmlContentType))
}

func TestUploadingRejectsDocumentsThatAreNotMusicXml(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

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
			t.Parallel()

			scoreId := uuid.New()

			res, err := client.PutScore(t.Context(), helpers.MusicXmlBody(tt.document),
				api.PutScoreParams{ScoreId: scoreId})
			require.NoError(t, err)

			assert.IsTypef(t, &api.PutScoreBadRequest{}, res,
				"uploading %s should be rejected as a bad request, got %#v", tt.name, res)
			assert.Zero(t, h.CountRows(t, "score_files", scoreId.String()),
				"a rejected document should not have been stored")
		})
	}
}

// TestUploadingAnUnknownInstrumentStoresNothing covers a document the parser
// accepts but the database cannot store, because the instrument is not part of
// the instrument enum. Whatever the API answers, it may not leave a document
// behind without the metadata that belongs to it.
func TestUploadingAnUnknownInstrumentStoresNothing(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	res, err := client.PutScore(t.Context(),
		helpers.MusicXmlBody(helpers.MusicXmlWithUnknownInstrument),
		api.PutScoreParams{ScoreId: scoreId})
	require.NoError(t, err)

	assert.IsTypef(t, &api.PutScoreBadRequest{}, res,
		"an unsupported instrument is a problem with the uploaded document, got %#v", res)
	assert.Zero(t, h.CountRows(t, "score_files", scoreId.String()),
		"a failed upload left the document behind without its metadata")
	assert.Zero(t, h.CountRows(t, "scores", scoreId.String()), "score metadata rows")
}

func TestUploadingAcceptsBothMusicXmlMediaTypes(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	tests := []struct {
		mediaType string
		body      api.PutScoreReq
	}{
		{
			mediaType: helpers.MusicXmlContentType,
			body:      helpers.MusicXmlBody(helpers.MusicXmlWithWorkAndMovement),
		},
		{
			mediaType: helpers.MusicXmlContentTypeWithXmlSuffix,
			body: &api.PutScoreReqApplicationVndRecordareMusicxmlXML{
				Data: strings.NewReader(helpers.MusicXmlWithWorkAndMovement),
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.mediaType, func(t *testing.T) {
			t.Parallel()

			res, err := client.PutScore(t.Context(), tt.body,
				api.PutScoreParams{ScoreId: uuid.New()})
			require.NoError(t, err)

			assert.IsTypef(t, &api.PutScoreOK{}, res,
				"content-type %q should be accepted, got %#v", tt.mediaType, res)
		})
	}
}

func TestFetchingAnUnknownScoreReturnsNotFound(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)
	unknownId := uuid.New()

	t.Run("metadata", func(t *testing.T) {
		t.Parallel()

		res, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: unknownId})
		require.NoError(t, err)
		assert.IsTypef(t, &api.GetScoreNotFound{}, res, "got %#v", res)
	})

	t.Run("document", func(t *testing.T) {
		t.Parallel()

		res, err := client.GetScore(t.Context(), api.GetScoreParams{
			ScoreId: unknownId,
			Accept:  api.NewOptString(helpers.MusicXmlContentType),
		})
		require.NoError(t, err)
		assert.IsTypef(t, &api.GetScoreNotFound{}, res, "got %#v", res)
	})
}

func TestListingScoresReturnsTheScoresInTheWindow(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	first := uuid.New()
	second := uuid.New()
	helpers.MustPutScore(t, client, first, helpers.MusicXmlWithWorkAndMovement)
	helpers.MustPutScore(t, client, second, helpers.MusicXmlWithTwoComposers)

	// What the window holds beyond these two is not this test's business: every
	// other test uploads into the same window, and emptying the table first
	// would pull those scores out from under them.
	t.Run("window covering both uploads", func(t *testing.T) {
		t.Parallel()

		scores := mustListScores(t, client, aWhileAgo(), soon())

		listed := make([]uuid.UUID, 0, len(scores))
		for _, score := range scores {
			listed = append(listed, score.ID)
		}
		assert.Subset(t, listed, []uuid.UUID{first, second},
			"a score uploaded within the window should be listed in it")
	})

	t.Run("window before the uploads", func(t *testing.T) {
		t.Parallel()

		scores := mustListScores(t, client,
			time.Now().Add(-48*time.Hour),
			time.Now().Add(-24*time.Hour))

		assert.Empty(t, scores, "scores changed today are not in a window that ended yesterday")
	})

	// A window is a pair of moments, and a moment says which one it is however
	// it is written. Said in a zone of its own it has to hold the same scores as
	// the same window said in UTC — the bound is compared as an instant, not as
	// the wall clock it reads.
	t.Run("window covering both uploads, said in another zone", func(t *testing.T) {
		t.Parallel()

		farEast := time.FixedZone("UTC+14", 14*60*60)
		farWest := time.FixedZone("UTC-11", -11*60*60)

		scores := mustListScores(t, client,
			aWhileAgo().In(farEast),
			soon().In(farWest))

		listed := make([]uuid.UUID, 0, len(scores))
		for _, score := range scores {
			listed = append(listed, score.ID)
		}
		assert.Subset(t, listed, []uuid.UUID{first, second},
			"the window a client wrote in its own zone should hold what the same window holds in UTC")
	})
}

func mustListScores(t *testing.T, client *helpers.ApiClient, since, until time.Time) api.GetScoresResponse {
	t.Helper()

	res, err := client.ListScores(t.Context(), api.ListScoresParams{
		ChangesSince: since,
		ChangesUntil: until,
	})
	require.NoError(t, err, "failed to list scores")

	scores, ok := res.(*api.GetScoresResponse)
	require.Truef(t, ok, "expected a page of scores, got %#v", res)
	return *scores
}

// TestTheCorrelationIdOfAFailureIsTheOneItWasLoggedUnder checks that a caller
// that ties its own requests together gets that same id back as the instance of
// whatever went wrong, so that reporting a failure is enough to find it.
func TestTheCorrelationIdOfAFailureIsTheOneItWasLoggedUnder(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)
	correlationId := uuid.NewString()

	res, err := client.GetScore(t.Context(), api.GetScoreParams{
		ScoreId:        uuid.New(),
		XCorrelationID: api.NewOptString(correlationId),
	})
	require.NoError(t, err)

	notFound, ok := res.(*api.GetScoreNotFound)
	require.Truef(t, ok, "got %#v", res)
	assert.Equal(t, "urn:uuid:"+correlationId, notFound.Instance)
}

func TestHealthzIsPublic(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	res, err := client.Healthz(t.Context(), api.HealthzParams{})
	require.NoError(t, err)

	ok, isOk := res.(*api.HealthzOK)
	require.Truef(t, isOk, "got %#v", res)
	assert.Equal(t, "OK", helpers.MustReadAll(t, ok.Data))
}

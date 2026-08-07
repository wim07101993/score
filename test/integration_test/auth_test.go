//go:build integration

package integration_test

import (
	"net/http"
	"testing"

	"score/internal/api"
	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTokensTheProviderDoesNotVouchForAreRejected(t *testing.T) {
	idp := helpers.Ensure(t, harness.IdentityProvider, "idp")

	tcs := []struct {
		name  string
		token string
	}{
		{name: "unknown token", token: uuid.NewString()},
		{name: "inactive token", token: idp.IssueInactiveToken(t)},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			securitySource := helpers.Ensure(t, harness.FakeSecuritySource, "FakeSecuritySource")
			client := helpers.Ensure(t, harness.ApiClient, "ApiClient")

			securitySource.Token = tc.token

			res, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: uuid.New()})
			require.NoError(t, err)

			assert.IsTypef(t, &api.GetScoreUnauthorized{}, res, "got %#v", res)
		})
	}
}

func TestReadingScoreMetadataRequiresTheViewerRole(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	scoreId := uuid.New()
	helpers.MustPutScore(t, editorClient(t), scoreId, helpers.MusicXmlWithWorkAndMovement)

	res, err := harness.ApiClient(t, idp.IssueToken(t)).
		GetScore(t.Context(), api.GetScoreParams{ScoreId: scoreId})
	require.NoError(t, err)

	assert.IsTypef(t, &api.GetScoreForbidden{}, res,
		"a user without the %s role should not be able to read score metadata, got %#v",
		auth.RoleScoreViewer, res)
}

// TestReadingTheScoreDocumentRequiresTheViewerRole guards the sheet music
// itself. Asking for the music-xml representation may not be a way around the
// role check that protects the metadata.
func TestReadingTheScoreDocumentRequiresTheViewerRole(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	scoreId := uuid.New()
	helpers.MustPutScore(t, editorClient(t), scoreId, helpers.MusicXmlWithWorkAndMovement)

	mediaTypes := []string{
		helpers.MusicXmlContentType,
		helpers.MusicXmlContentTypeWithXmlSuffix,
	}

	for _, mediaType := range mediaTypes {
		t.Run(mediaType, func(t *testing.T) {
			res, err := harness.ApiClient(t, idp.IssueToken(t)).
				GetScore(t.Context(), api.GetScoreParams{
					ScoreId: scoreId,
					Accept:  api.NewOptString(mediaType),
				})
			require.NoError(t, err)

			assert.IsTypef(t, &api.GetScoreForbidden{}, res,
				"a user without the %s role should not be able to download the score document, got %#v",
				auth.RoleScoreViewer, res)
		})
	}
}

func TestListingScoresRequiresTheViewerRole(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	res, err := harness.ApiClient(t, idp.IssueToken(t)).
		ListScores(t.Context(), api.ListScoresParams{
			ChangesSince: aWhileAgo(),
			ChangesUntil: soon(),
		})
	require.NoError(t, err)

	assert.IsTypef(t, &api.ListScoresForbidden{}, res,
		"a user without the %s role should not be able to list scores, got %#v",
		auth.RoleScoreViewer, res)
}

func TestUploadingRequiresTheEditorRole(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	tests := []struct {
		name  string
		token string
	}{
		{name: "no roles", token: idp.IssueToken(t)},
		{name: "viewer only", token: idp.IssueToken(t, auth.RoleScoreViewer)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			scoreId := uuid.New()

			res, err := harness.ApiClient(t, tt.token).PutScore(t.Context(),
				helpers.MusicXmlBody(helpers.MusicXmlWithWorkAndMovement),
				api.PutScoreParams{ScoreId: scoreId})
			require.NoError(t, err)

			assert.IsTypef(t, &api.PutScoreForbidden{}, res,
				"a user with %s should not be able to upload a score, got %#v", tt.name, res)
			assert.Zerof(t, harness.CountRows(t, "score_files", scoreId.String()),
				"a rejected upload should not have stored a document")
		})
	}
}

func TestTheEditorRoleAllowsUploading(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	res, err := harness.ApiClient(t, idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)).
		PutScore(t.Context(), helpers.MusicXmlBody(helpers.MusicXmlWithWorkAndMovement),
			api.PutScoreParams{ScoreId: uuid.New()})
	require.NoError(t, err)

	assert.IsTypef(t, &api.PutScoreOK{}, res, "an editor should be able to upload, got %#v", res)
}

// TestIdentityProviderFailuresAreNotReportedAsInvalidTokens covers the case
// where the API cannot introspect a token, for instance because its own client
// credentials are wrong. That is a server-side problem: telling the caller
// their token is invalid sends them off to debug the wrong thing.
func TestIdentityProviderFailuresAreNotReportedAsInvalidTokens(t *testing.T) {
	idp := harness.EnsureIdentityProvider(t)

	tests := []struct {
		name  string
		token string
	}{
		{name: "introspection fails", token: idp.IssueUnintrospectableToken(t)},
		{name: "user info fails", token: idp.IssueTokenWithoutUserInfo(t)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := harness.ApiClient(t, tt.token).
				GetScore(t.Context(), api.GetScoreParams{ScoreId: uuid.New()})

			// A status the document does not describe comes back as an error
			// wrapping what was answered, rather than as a response variant.
			var unknown *api.XxxUnknownErrorStatusCode
			require.ErrorAsf(t, err, &unknown,
				"a failing %s call should be answered as a server error, got %v", tt.name, err)
			assert.GreaterOrEqualf(t, unknown.StatusCode, http.StatusInternalServerError,
				"a failing %s call should be reported as a server error, got %d", tt.name, unknown.StatusCode)
		})
	}
}

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
	t.Parallel()

	idp := helpers.Ensure(t, harness.NewScope().IdentityProvider, "idp")

	tcs := []struct {
		name  string
		token string
	}{
		{name: "unknown token", token: uuid.NewString()},
		{name: "inactive token", token: idp.IssueInactiveToken(t)},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			// Its own scope: a subtest may not re-point a security source
			// another subtest is calling through.
			client := helpers.Ensure(t, harness.NewScope().ApiClient, "ApiClient")

			client.Security.Token = tc.token

			res, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: uuid.New()})
			require.NoError(t, err)

			assert.IsTypef(t, &api.GetScoreUnauthorized{}, res, "got %#v", res)
		})
	}
}

func TestReadingScoreMetadataRequiresTheViewerRole(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	scoreId := uuid.New()
	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithWorkAndMovement)

	client.Security.Token = idp.IssueToken(t)

	res, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: scoreId})
	require.NoError(t, err)

	assert.IsTypef(t, &api.GetScoreForbidden{}, res,
		"a user without the %s role should not be able to read score metadata, got %#v",
		auth.RoleScoreViewer, res)
}

// TestReadingTheScoreDocumentRequiresTheViewerRole guards the sheet music
// itself. Asking for the music-xml representation may not be a way around the
// role check that protects the metadata.
func TestReadingTheScoreDocumentRequiresTheViewerRole(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	scoreId := uuid.New()
	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithWorkAndMovement)

	mediaTypes := []string{
		helpers.MusicXmlContentType,
		helpers.MusicXmlContentTypeWithXmlSuffix,
	}

	for _, mediaType := range mediaTypes {
		t.Run(mediaType, func(t *testing.T) {
			t.Parallel()

			// Its own client: the one above is the editor that uploaded the
			// score, and a subtest may not re-point it while another is using it.
			// Its own scope: a subtest may not re-point a security source
			// another subtest is calling through.
			client := helpers.Ensure(t, harness.NewScope().ApiClient, "ApiClient")

			client.Security.Token = idp.IssueToken(t)

			res, err := client.GetScore(t.Context(), api.GetScoreParams{
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
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t)

	res, err := client.ListScores(t.Context(), api.ListScoresParams{
		ChangesSince: aWhileAgo(),
		ChangesUntil: soon(),
	})
	require.NoError(t, err)

	assert.IsTypef(t, &api.ListScoresForbidden{}, res,
		"a user without the %s role should not be able to list scores, got %#v",
		auth.RoleScoreViewer, res)
}

func TestUploadingRequiresTheEditorRole(t *testing.T) {
	t.Parallel()

	idp := helpers.Ensure(t, harness.NewScope().IdentityProvider, "idp")

	tcs := []struct {
		name  string
		roles []string
	}{
		{name: "no roles", roles: nil},
		{name: "viewer only", roles: []string{auth.RoleScoreViewer}},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			// Its own scope: a subtest may not re-point a security source
			// another subtest is calling through.
			h := harness.NewScope()
			client := helpers.Ensure(t, h.ApiClient, "ApiClient")

			client.Security.Token = idp.IssueToken(t, tc.roles...)

			scoreId := uuid.New()
			res, err := client.PutScore(t.Context(),
				helpers.MusicXmlBody(helpers.MusicXmlWithWorkAndMovement),
				api.PutScoreParams{ScoreId: scoreId})
			require.NoError(t, err)

			assert.IsTypef(t, &api.PutScoreForbidden{}, res,
				"a user with %s should not be able to upload a score, got %#v", tc.name, res)
			assert.Zerof(t, h.CountRows(t, "score_files", scoreId.String()),
				"a rejected upload should not have stored a document")
		})
	}
}

func TestTheEditorRoleAllowsUploading(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	res, err := client.PutScore(t.Context(),
		helpers.MusicXmlBody(helpers.MusicXmlWithWorkAndMovement),
		api.PutScoreParams{ScoreId: uuid.New()})
	require.NoError(t, err)

	assert.IsTypef(t, &api.PutScoreOK{}, res, "an editor should be able to upload, got %#v", res)
}

// TestIdentityProviderFailuresAreNotReportedAsInvalidTokens covers the case
// where the API cannot introspect a token, for instance because its own client
// credentials are wrong. That is a server-side problem: telling the caller
// their token is invalid sends them off to debug the wrong thing.
func TestIdentityProviderFailuresAreNotReportedAsInvalidTokens(t *testing.T) {
	t.Parallel()

	idp := helpers.Ensure(t, harness.NewScope().IdentityProvider, "idp")

	tcs := []struct {
		name  string
		token string
	}{
		{name: "introspection fails", token: idp.IssueUnintrospectableToken(t)},
		{name: "user info fails", token: idp.IssueTokenWithoutUserInfo(t)},
	}

	for _, tc := range tcs {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			// Its own scope: a subtest may not re-point a security source
			// another subtest is calling through.
			client := helpers.Ensure(t, harness.NewScope().ApiClient, "ApiClient")

			client.Security.Token = tc.token

			_, err := client.GetScore(t.Context(), api.GetScoreParams{ScoreId: uuid.New()})

			// A status the document does not describe comes back as an error
			// wrapping what was answered, rather than as a response variant.
			var unknown *api.XxxUnknownErrorStatusCode
			require.ErrorAsf(t, err, &unknown,
				"a failing %s call should be answered as a server error, got %v", tc.name, err)
			assert.GreaterOrEqualf(t, unknown.StatusCode, http.StatusInternalServerError,
				"a failing %s call should be reported as a server error, got %d", tc.name, unknown.StatusCode)
		})
	}
}

//go:build integration

package integration_test

import (
	"net/http"
	"testing"

	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestRequestsWithoutAValidTokenAreRejected(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)
	scoreId := uuid.NewString()

	tests := []struct {
		name          string
		authorization string
	}{
		{name: "no authorization header", authorization: ""},
		{name: "wrong scheme", authorization: "Basic dXNlcjpwYXNzd29yZA=="},
		{name: "scheme without a token", authorization: "Bearer"},
		{name: "empty token", authorization: "Bearer "},
		{name: "unknown token", authorization: "Bearer " + uuid.NewString()},
		{name: "inactive token", authorization: "Bearer " + idp.IssueInactiveToken(t)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
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

func TestReadingScoreMetadataRequiresTheViewerRole(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, idp.IssueToken(t, auth.RoleScoreEditor), helpers.MusicXmlWithWorkAndMovement)

	res := client.GetScore(t, scoreId, idp.IssueToken(t))

	assert.Equalf(t, http.StatusForbidden, res.StatusCode,
		"a user without the %s role should not be able to read score metadata: %s",
		auth.RoleScoreViewer, res.Text())
}

// TestReadingTheScoreDocumentRequiresTheViewerRole guards the sheet music
// itself. Asking for the music-xml representation may not be a way around the
// role check that protects the metadata.
func TestReadingTheScoreDocumentRequiresTheViewerRole(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, idp.IssueToken(t, auth.RoleScoreEditor), helpers.MusicXmlWithWorkAndMovement)

	mediaTypes := []string{
		helpers.MusicXmlContentType,
		helpers.MusicXmlContentTypeWithXmlSuffix,
	}

	for _, mediaType := range mediaTypes {
		t.Run(mediaType, func(t *testing.T) {
			res := client.Do(t, helpers.Request{
				Method: http.MethodGet,
				Path:   "/scores/" + scoreId,
				Token:  idp.IssueToken(t),
				Accept: mediaType,
			})

			assert.Equalf(t, http.StatusForbidden, res.StatusCode,
				"a user without the %s role should not be able to download the score document",
				auth.RoleScoreViewer)
			assert.NotContains(t, res.Text(), "score-partwise",
				"the score document was handed to a user without the %s role", auth.RoleScoreViewer)
		})
	}
}

func TestListingScoresRequiresTheViewerRole(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	res := client.ListScores(t, idp.IssueToken(t), aWhileAgo(), soon())

	assert.Equalf(t, http.StatusForbidden, res.StatusCode,
		"a user without the %s role should not be able to list scores: %s",
		auth.RoleScoreViewer, res.Text())
}

func TestUploadingRequiresTheEditorRole(t *testing.T) {
	client := harness.EnsureScoresClient(t)
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
			scoreId := uuid.NewString()
			res := client.PutScore(t, scoreId, tt.token, helpers.MusicXmlWithWorkAndMovement)

			assert.Equalf(t, http.StatusForbidden, res.StatusCode,
				"a user with %s should not be able to upload a score: %s", tt.name, res.Text())
			assert.Zerof(t, harness.CountRows(t, "score_files", scoreId),
				"a rejected upload should not have stored a document")
		})
	}
}

func TestTheEditorRoleAllowsUploading(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	res := client.PutScore(t, uuid.NewString(),
		idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor),
		helpers.MusicXmlWithWorkAndMovement)

	assert.Equalf(t, http.StatusOK, res.StatusCode, "an editor should be able to upload: %s", res.Text())
}

// TestIdentityProviderFailuresAreNotReportedAsInvalidTokens covers the case
// where the API cannot introspect a token, for instance because its own client
// credentials are wrong. That is a server-side problem: telling the caller
// their token is invalid sends them off to debug the wrong thing.
func TestIdentityProviderFailuresAreNotReportedAsInvalidTokens(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	t.Run("introspection fails", func(t *testing.T) {
		res := client.GetScore(t, uuid.NewString(), idp.IssueUnintrospectableToken(t))

		assert.GreaterOrEqualf(t, res.StatusCode, http.StatusInternalServerError,
			"a failing introspection call should be reported as a server error, got %d: %s",
			res.StatusCode, res.Text())
	})

	t.Run("user info fails", func(t *testing.T) {
		res := client.GetScore(t, uuid.NewString(), idp.IssueTokenWithoutUserInfo(t))

		assert.GreaterOrEqualf(t, res.StatusCode, http.StatusInternalServerError,
			"a failing user-info call should be reported as a server error, got %d: %s",
			res.StatusCode, res.Text())
	})
}

func TestPreflightRequestsDoNotRequireAuthentication(t *testing.T) {
	client := harness.EnsureScoresClient(t)

	res := client.Do(t, helpers.Request{
		Method: http.MethodOptions,
		Path:   "/scores/" + uuid.NewString(),
	})

	assert.Equal(t, http.StatusOK, res.StatusCode, "a preflight request should be answered")
	assert.NotEmpty(t, res.Headers.Get("Access-Control-Allow-Origin"))
	assert.NotEmpty(t, res.Headers.Get("Access-Control-Allow-Methods"))
}

func TestHealthzIsPublic(t *testing.T) {
	client := harness.EnsureScoresClient(t)

	res := client.Healthz(t)

	assert.Equal(t, http.StatusOK, res.StatusCode)
	assert.Equal(t, "OK", res.Text())
}

package helpers

import (
	"context"
	"io"
	"strings"
	"testing"

	"score/internal/api"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

// MusicXmlContentType is the media type the API accepts and returns score
// documents as.
const MusicXmlContentType = "application/vnd.recordare.musicxml"

// MusicXmlContentTypeWithXmlSuffix is the second media type the API accepts for
// the same thing.
const MusicXmlContentTypeWithXmlSuffix = "application/vnd.recordare.musicxml+xml"

// ApiClient is the client generated from the same document the server is
// generated from, talking to the running API as a caller holding the given
// token. It is what the functional tests call the API with: what the API does
// is worth testing, how it is routed and marshalled is not.
//
// A test gets a client per caller it wants to be, rather than threading a token
// through every call.
func (h *Harness) ApiClient(t *testing.T, token string) *api.Client {
	t.Helper()

	client, err := api.NewClient(
		h.EnsureApiServer(t).URL,
		bearerToken(token),
		api.WithClient(ensure(t, h.HttpClient, "http client")),
	)
	require.NoError(t, err, "failed to build the api client")
	return client
}

// bearerToken answers every operation with the one token it was built for.
type bearerToken string

func (b bearerToken) OAuth2(ctx context.Context, operationName api.OperationName) (api.OAuth2, error) {
	return api.OAuth2{Token: string(b)}, nil
}

// MusicXmlBody is a document as the API reads it.
func MusicXmlBody(document string) *api.PutScoreReqApplicationVndRecordareMusicxml {
	return &api.PutScoreReqApplicationVndRecordareMusicxml{Data: strings.NewReader(document)}
}

// MustPutScore uploads a document and fails the test unless the API accepted
// it. It is how a test arranges the scores it is actually about.
func MustPutScore(t *testing.T, client *api.Client, scoreId uuid.UUID, document string) {
	t.Helper()

	res, err := client.PutScore(t.Context(), MusicXmlBody(document),
		api.PutScoreParams{ScoreId: scoreId})
	require.NoErrorf(t, err, "failed to upload score %s", scoreId)
	require.IsTypef(t, &api.PutScoreOK{}, res, "failed to upload score %s: %#v", scoreId, res)
}

// ReadAll is the document out of a music-xml response.
func ReadAll(t *testing.T, r io.Reader) string {
	t.Helper()

	document, err := io.ReadAll(r)
	require.NoError(t, err, "failed to read the response document")
	return string(document)
}

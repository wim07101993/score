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

const (
	MusicXmlContentType              = "application/vnd.recordare.musicxml"
	MusicXmlContentTypeWithXmlSuffix = "application/vnd.recordare.musicxml+xml"
)

// MusicXmlBody is a document as the API reads it.
func MusicXmlBody(document string) *api.PutScoreReqApplicationVndRecordareMusicxml {
	return &api.PutScoreReqApplicationVndRecordareMusicxml{Data: strings.NewReader(document)}
}

func MustPutScore(t *testing.T, client *api.Client, scoreId uuid.UUID, document string) {
	t.Helper()

	res, err := client.PutScore(
		t.Context(),
		MusicXmlBody(document),
		api.PutScoreParams{ScoreId: scoreId},
	)

	require.NoErrorf(t, err, "failed to upload score %s", scoreId)
	require.IsTypef(t, &api.PutScoreOK{}, res, "failed to upload score %s: %#v", scoreId, res)
}

func MustReadAll(t *testing.T, r io.Reader) string {
	t.Helper()

	document, err := io.ReadAll(r)
	require.NoError(t, err, "failed to read the response document")
	return string(document)
}

type FakeSecuritySource struct {
	Token  string
	Scopes []string
}

func (f *FakeSecuritySource) OAuth2(ctx context.Context, operationName api.OperationName) (api.OAuth2, error) {
	return api.OAuth2{
		Token:  f.Token,
		Scopes: f.Scopes,
	}, nil
}

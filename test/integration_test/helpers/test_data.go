package helpers

import (
	"score/internal/auth"
	"testing"

	"github.com/google/uuid"
)

func (h *Harness) CreateScore(t *testing.T) string {
	t.Helper()

	idp := h.EnsureIdentityProvider(t)
	token := idp.IssueToken(t, IssueTokenInput{Roles: []string{auth.RoleScoreEditor}})

	client := h.EnsureScoresClient(t)
	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, token, MusicXmlWithWorkAndMovement)
	return scoreId
}

// anEntry is a set entry with nothing remarkable about it.
func anEntry(scoreId string) helpers.SetEntry {
	return helpers.SetEntry{Id: uuid.NewString(), ScoreId: scoreId, HiddenParts: []string{}}
}

// aPlayer is a user who may look at scores and build sets, with a known address
// so that sets can be shared with them.
func aPlayer(t *testing.T, email string) string {
	t.Helper()
	return harness.EnsureIdentityProvider(t).
		IssueTokenForEmail(t, email, auth.RoleScoreViewer)
}

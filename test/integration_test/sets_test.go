//go:build integration

package integration_test

import (
	"net/http"
	"score/internal/auth"
	"testing"
	"time"

	"score/test/integration_test/helpers"

	"github.com/go-faker/faker/v4"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------
// A SET IS A RUNNING ORDER
// ---------------------------------------------------------------------------

func TestCreateSet(t *testing.T) {
	t.Parallel()

	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)
	token := idp.IssueToken(t, helpers.IssueTokenInput{
		Roles: []string{auth.RoleScoreViewer},
	})

	t.Run("ok", func(t *testing.T) {
		t.Parallel()

		t.Run("basic", func(t *testing.T) {
			t.Parallel()

			title:= faker.Sentence()
			description := faker.Paragraph()


			setId := uuid.NewString()
			client.MustPutSet(t, setId, token, helpers.WriteSet{
				Title:       title,
				Description: description,
			})

			saved := client.GetSet(t, setId, token).DecodeSet(t)

			assert.Equal(t, setId, saved.Id)
			assert.Equal(t, title, saved.Title)
			assert.Equal(t, description, saved.Description)
			assert.True(t, saved.IsOwner, "the user who created a set owns it")
			assert.Nil(t, saved.DeletedAt)
			assert.NotNil(t, saved.Entries, "entries should be an empty list, never null")
			assert.NotNil(t, saved.SharedWith, "shared_with should be an empty list, never null")
		})
	})

	// The order of a set is the order of the gig, so it is kept exactly as it was
	// given rather than in whatever order the database finds convenient.
	func
	TestASetIsPlayedInTheOrderItWasGivenIn(t * testing.T)
	{
		client := harness.EnsureScoresClient(t)
		idp := harness.EnsureIdentityProvider(t)
		token := idp.IssueToken(t, helpers.IssueTokenInput{
			Email: "order@test.localhost",
			Roles: []string{auth.RoleScoreViewer},
		})

		first, second, third := aScore(t), aScore(t), aScore(t)

		setId := uuid.NewString()
		client.MustPutSet(t, setId, token, helpers.WriteSet{
			Title:   "Running order",
			Entries: []helpers.SetEntry{anEntry(third), anEntry(first), anEntry(second)},
		})

		saved := client.GetSet(t, setId, token).DecodeSet(t)

		assert.Equal(t, []string{third, first, second}, saved.ScoreIds())
	}

	func
	TestReorderingASetIsSavedAsTheNewOrder(t * testing.T)
	{
		client := harness.EnsureScoresClient(t)
		idp := harness.EnsureIdentityProvider(t)
		token := idp.IssueToken(t, helpers.IssueTokenInput{
			Email: "reorder@test.localhost",
			Roles: []string{auth.RoleScoreViewer},
		})

		first, second := aScore(t), aScore(t)
		firstEntry, secondEntry := anEntry(first), anEntry(second)

		setId := uuid.NewString()
		client.MustPutSet(t, setId, token, helpers.WriteSet{
			Title:   "Before",
			Entries: []helpers.SetEntry{firstEntry, secondEntry},
		})

		client.MustPutSet(t, setId, token, helpers.WriteSet{
			Title:   "After",
			Entries: []helpers.SetEntry{secondEntry, firstEntry},
		})

		saved := client.GetSet(t, setId, token).DecodeSet(t)

		assert.Equal(t, []string{second, first}, saved.ScoreIds())
		assert.Equal(t, "After", saved.Title)
	}

	// A song can come round twice in a gig, and the second time is its own entry:
	// its own place in the order, its own note, and its own key.
	func
	TestTheSameScoreCanBePlayedTwiceInASet(t * testing.T)
	{
		client := harness.EnsureScoresClient(t)
		idp := harness.EnsureIdentityProvider(t)
		token := idp.IssueToken(t, helpers.IssueTokenInput{
			Email: "encore@test.localhost",
			Roles: []string{auth.RoleScoreViewer},
		})

		scoreId := aScore(t)
		opener := helpers.SetEntry{
			Id: uuid.NewString(), ScoreId: scoreId,
			Description: "opener, full band", Transposition: 0, HiddenParts: []string{},
		}
		encore := helpers.SetEntry{
			Id: uuid.NewString(), ScoreId: scoreId,
			Description: "encore, voice only", Transposition: -2, HiddenParts: []string{"P2"},
		}

		setId := uuid.NewString()
		client.MustPutSet(t, setId, token, helpers.WriteSet{
			Title:   "Twice round",
			Entries: []helpers.SetEntry{opener, anEntry(aScore(t)), encore},
		})

		saved := client.GetSet(t, setId, token).DecodeSet(t)

		require.Len(t, saved.Entries, 3)
		assert.Equal(t, scoreId, saved.Entries[0].ScoreId)
		assert.Equal(t, scoreId, saved.Entries[2].ScoreId)

		assert.Equal(t, "opener, full band", saved.Entries[0].Description)
		assert.Equal(t, 0, saved.Entries[0].Transposition)
		assert.Empty(t, saved.Entries[0].HiddenParts)

		assert.Equal(t, "encore, voice only", saved.Entries[2].Description)
		assert.Equal(t, -2, saved.Entries[2].Transposition, "the two times round are played in different keys")
		assert.Equal(t, []string{"P2"}, saved.Entries[2].HiddenParts)
	}
}

// ---------------------------------------------------------------------------
// HOW A SCORE IS PLAYED IN THIS SET
// ---------------------------------------------------------------------------

// The key and the parts on screen are what the player needs back when they open
// a score from inside a set, so they have to survive the round trip exactly.
func TestHowAScoreIsPlayedIsKeptWithTheSet(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "arrangement@test.localhost")

	scoreId := aScore(t)
	setId := uuid.NewString()
	client.MustPutSet(t, setId, token, helpers.WriteSet{
		Title: "Arrangements",
		Entries: []helpers.SetEntry{{
			Id:            uuid.NewString(),
			ScoreId:       scoreId,
			Description:   "down a third for the singer",
			Transposition: -4,
			HiddenParts:   []string{"P2", "P3"},
		}},
	})

	saved := client.GetSet(t, setId, token).DecodeSet(t)

	require.Len(t, saved.Entries, 1)
	assert.Equal(t, -4, saved.Entries[0].Transposition)
	assert.Equal(t, []string{"P2", "P3"}, saved.Entries[0].HiddenParts)
	assert.Equal(t, "down a third for the singer", saved.Entries[0].Description)
}

// Playing a score in another key is a property of the set, not of the score.
func TestPlayingAScoreInAnotherKeyLeavesTheScoreAlone(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "untouched@test.localhost")
	editor := editorToken(t)

	scoreId := uuid.NewString()
	client.MustPutScore(t, scoreId, editor, helpers.MusicXmlWithWorkAndMovement)

	client.MustPutSet(t, uuid.NewString(), token, helpers.WriteSet{
		Title:   "Transposed",
		Entries: []helpers.SetEntry{{Id: uuid.NewString(), ScoreId: scoreId, Transposition: 5}},
	})

	document := client.GetScoreMusicXml(t, scoreId, editor)
	assert.Equal(t, helpers.MusicXmlWithWorkAndMovement, document.Text(),
		"putting a score in a set changed the score itself")
}

func TestASetRefusesATranspositionItCannotPlay(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "range@test.localhost")
	scoreId := aScore(t)

	for _, semitones := range []int{13, -13, 200} {
		res := client.PutSet(t, uuid.NewString(), token, helpers.WriteSet{
			Title:   "Out of range",
			Entries: []helpers.SetEntry{{Id: uuid.NewString(), ScoreId: scoreId, Transposition: semitones}},
		})

		assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
			"a transposition of %d semitones should be refused: %s", semitones, res.Text())
	}
}

func TestASetRefusesAScoreThatDoesNotExist(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "ghost@test.localhost")

	setId := uuid.NewString()
	res := client.PutSet(t, setId, token, helpers.WriteSet{
		Title:   "Ghost",
		Entries: []helpers.SetEntry{anEntry(uuid.NewString())},
	})

	assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
		"a set naming a score that does not exist should be refused: %s", res.Text())
	assert.Equal(t, http.StatusNotFound, client.GetSet(t, setId, token).StatusCode,
		"a refused set should not have been stored")
}

func TestASetRefusesTheSameEntryTwice(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "duplicate@test.localhost")

	entry := anEntry(aScore(t))
	res := client.PutSet(t, uuid.NewString(), token, helpers.WriteSet{
		Title:   "Duplicate",
		Entries: []helpers.SetEntry{entry, entry},
	})

	assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
		"two entries with the same id should be refused: %s", res.Text())
}

// ---------------------------------------------------------------------------
// A SET BELONGS TO SOMEBODY
// ---------------------------------------------------------------------------

func TestASetIsNotVisibleToEveryone(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "owner@test.localhost")
	stranger := aPlayer(t, "stranger@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{Title: "Private"})

	res := client.GetSet(t, setId, stranger)

	assert.Equal(t, http.StatusNotFound, res.StatusCode,
		"a set someone has nothing to do with should not be readable")
	assert.NotContains(t, res.Text(), "Private", "the title of another user's set leaked")
}

func TestListingSetsOnlyShowsYourOwn(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "mine@test.localhost")
	stranger := aPlayer(t, "notmine@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{Title: "Mine"})

	mine := client.ListSets(t, owner, aWhileAgo(), soon()).DecodeSets(t)
	_, found := helpers.FindSet(mine, setId)
	assert.True(t, found, "a set should be in its owner's list")

	theirs := client.ListSets(t, stranger, aWhileAgo(), soon()).DecodeSets(t)
	_, found = helpers.FindSet(theirs, setId)
	assert.False(t, found, "another user's set should not be in the list")
}

func TestOnlyTheOwnerCanChangeASet(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "keeper@test.localhost")
	other := aPlayer(t, "meddler@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{Title: "Kept"})

	res := client.PutSet(t, setId, other, helpers.WriteSet{Title: "Meddled with"})

	assert.Equal(t, http.StatusForbidden, res.StatusCode, res.Text())
	assert.Equal(t, "Kept", client.GetSet(t, setId, owner).DecodeSet(t).Title,
		"a set was changed by someone who does not own it")
}

// ---------------------------------------------------------------------------
// SHARING
// ---------------------------------------------------------------------------

func TestASharedSetCanBeReadByThePersonItIsSharedWith(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "bandleader@test.localhost")
	bandMember := aPlayer(t, "bassist@test.localhost")

	scoreId := aScore(t)
	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Friday night",
		Entries:    []helpers.SetEntry{{Id: uuid.NewString(), ScoreId: scoreId, Transposition: 2, Description: "count it in"}},
		SharedWith: []string{"bassist@test.localhost"},
	})

	res := client.GetSet(t, setId, bandMember)
	require.Equalf(t, http.StatusOK, res.StatusCode, "a shared set should be readable: %s", res.Text())

	shared := res.DecodeSet(t)
	assert.Equal(t, "Friday night", shared.Title)
	assert.False(t, shared.IsOwner, "a set someone shared is not theirs")
	require.Len(t, shared.Entries, 1)
	assert.Equal(t, 2, shared.Entries[0].Transposition, "the band should see the key the set is played in")
	assert.Equal(t, "count it in", shared.Entries[0].Description)
}

func TestASharedSetIsInTheListOfThePersonItIsSharedWith(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "leader2@test.localhost")
	bandMember := aPlayer(t, "drummer@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Saturday night",
		SharedWith: []string{"drummer@test.localhost"},
	})

	sets := client.ListSets(t, bandMember, aWhileAgo(), soon()).DecodeSets(t)

	found, ok := helpers.FindSet(sets, setId)
	require.True(t, ok, "a shared set should be in the list of the person it is shared with")
	assert.False(t, found.IsOwner)
}

// Sharing is by address, and an address that differs only in case is the same
// address: nobody types their email the same way twice.
func TestSharingIgnoresTheCaseOfAnAddress(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "leader3@test.localhost")
	bandMember := aPlayer(t, "guitarist@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Case",
		SharedWith: []string{"  GuiTarist@Test.Localhost  "},
	})

	assert.Equal(t, http.StatusOK, client.GetSet(t, setId, bandMember).StatusCode)
}

// Sharing is for reading. A band member seeing the set is not a band member
// rewriting it.
func TestSharingASetDoesNotAllowChangingIt(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "leader4@test.localhost")
	bandMember := aPlayer(t, "pianist@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Read only",
		SharedWith: []string{"pianist@test.localhost"},
	})

	write := client.PutSet(t, setId, bandMember, helpers.WriteSet{Title: "Rewritten"})
	assert.Equal(t, http.StatusForbidden, write.StatusCode, write.Text())

	remove := client.DeleteSet(t, setId, bandMember)
	assert.Equal(t, http.StatusNotFound, remove.StatusCode,
		"a shared set is not the reader's to delete: %s", remove.Text())

	assert.Equal(t, "Read only", client.GetSet(t, setId, owner).DecodeSet(t).Title)
}

// Who else a set is shared with is the owner's business.
func TestThePeopleASetIsSharedWithAreOnlyShownToTheOwner(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "leader5@test.localhost")
	bandMember := aPlayer(t, "singer@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Who else",
		SharedWith: []string{"singer@test.localhost", "trumpet@test.localhost"},
	})

	asOwner := client.GetSet(t, setId, owner).DecodeSet(t)
	assert.ElementsMatch(t, []string{"singer@test.localhost", "trumpet@test.localhost"}, asOwner.SharedWith)

	res := client.GetSet(t, setId, bandMember)
	assert.Empty(t, res.DecodeSet(t).SharedWith, "a reader should not learn who else has the set")
	assert.NotContains(t, res.Text(), "trumpet@test.localhost", "another band member's address leaked")
}

func TestUnsharingASetTakesItAway(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	owner := aPlayer(t, "leader6@test.localhost")
	bandMember := aPlayer(t, "fiddle@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, owner, helpers.WriteSet{
		Title:      "Shared for now",
		SharedWith: []string{"fiddle@test.localhost"},
	})
	require.Equal(t, http.StatusOK, client.GetSet(t, setId, bandMember).StatusCode)

	client.MustPutSet(t, setId, owner, helpers.WriteSet{Title: "Shared for now", SharedWith: []string{}})

	assert.Equal(t, http.StatusNotFound, client.GetSet(t, setId, bandMember).StatusCode,
		"a set that is no longer shared should no longer be readable")
}

// ---------------------------------------------------------------------------
// SYNCING BETWEEN DEVICES
// ---------------------------------------------------------------------------

// A set is edited offline and synced afterwards, so a set deleted on one device
// has to be recognisable as deleted by another that still has it. Dropping the
// row would leave the other device with a set nothing ever contradicts.
func TestADeletedSetIsReportedAsDeletedRatherThanVanishing(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "twodevices@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, token, helpers.WriteSet{Title: "Cancelled gig"})

	require.Equal(t, http.StatusNoContent, client.DeleteSet(t, setId, token).StatusCode)

	sets := client.ListSets(t, token, aWhileAgo(), soon()).DecodeSets(t)
	deleted, found := helpers.FindSet(sets, setId)

	require.True(t, found, "a deleted set should still be reported so other devices drop it")
	assert.NotNil(t, deleted.DeletedAt, "the set is not marked as deleted")
}

func TestADeletedSetCannotBeReadAnyMore(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "gone@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, token, helpers.WriteSet{Title: "Gone"})
	require.Equal(t, http.StatusNoContent, client.DeleteSet(t, setId, token).StatusCode)

	assert.Equal(t, http.StatusNotFound, client.GetSet(t, setId, token).StatusCode,
		"a deleted set should not be readable")
	assert.Equal(t, http.StatusNotFound, client.DeleteSet(t, setId, token).StatusCode,
		"deleting a set that is already gone is not a server error")
}

// A device that has been offline can still be holding a set that was deleted
// elsewhere. Editing it says the set should exist again, which is the only way
// back for a set that was deleted by mistake.
func TestWritingADeletedSetAgainBringsItBack(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "backagain@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, token, helpers.WriteSet{Title: "Cancelled"})
	require.Equal(t, http.StatusNoContent, client.DeleteSet(t, setId, token).StatusCode)

	client.MustPutSet(t, setId, token, helpers.WriteSet{Title: "Back on"})

	revived := client.GetSet(t, setId, token).DecodeSet(t)
	assert.Equal(t, "Back on", revived.Title)
	assert.Nil(t, revived.DeletedAt)
}

// A device that was offline while a set was edited should get it on its next
// sync, which is what the change window is for.
func TestOnlyTheSetsChangedInTheWindowAreListed(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "window@test.localhost")

	setId := uuid.NewString()
	client.MustPutSet(t, setId, token, helpers.WriteSet{Title: "Recent"})

	inWindow := client.ListSets(t, token, aWhileAgo(), soon()).DecodeSets(t)
	_, found := helpers.FindSet(inWindow, setId)
	assert.True(t, found, "a set changed just now should be in a window that covers now")

	beforeWindow := client.ListSets(t, token,
		time.Now().Add(-48*time.Hour), time.Now().Add(-24*time.Hour)).DecodeSets(t)
	_, found = helpers.FindSet(beforeWindow, setId)
	assert.False(t, found, "a set changed today is not in a window that ended yesterday")
}

func TestListingSetsRequiresAChangeWindow(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "nowindow@test.localhost")

	tests := []struct {
		name string
		path string
	}{
		{name: "no parameters", path: "/sets"},
		{name: "only Changes-Since", path: "/sets?Changes-Since=20240101T000000"},
		{name: "only Changes-Until", path: "/sets?Changes-Until=20240101T000000"},
		{name: "malformed Changes-Since", path: "/sets?Changes-Since=yesterday&Changes-Until=20240101T000000"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			res := client.Do(t, helpers.Request{Method: http.MethodGet, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
				"listing sets with %s should be rejected: %s", tt.name, res.Text())
		})
	}
}

// ---------------------------------------------------------------------------
// THE REST OF THE ENDPOINT
// ---------------------------------------------------------------------------

func TestSetsRequireAValidToken(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	setId := uuid.NewString()

	for _, tt := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "reading one", method: http.MethodGet, path: "/sets/" + setId},
		{name: "listing", method: http.MethodGet, path: "/sets?Changes-Since=20240101T000000&Changes-Until=20240101T000000"},
		{name: "writing", method: http.MethodPut, path: "/sets/" + setId},
		{name: "deleting", method: http.MethodDelete, path: "/sets/" + setId},
	} {
		t.Run(tt.name, func(t *testing.T) {
			res := client.Do(t, helpers.Request{Method: tt.method, Path: tt.path})
			assert.Equal(t, http.StatusUnauthorized, res.StatusCode, res.Text())
		})
	}
}

// A set names scores and changes nothing about them, so building one asks no
// more of a user than reading the scores in it.
func TestSetsRequireTheViewerRole(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	idp := harness.EnsureIdentityProvider(t)

	withoutRole := idp.IssueTokenForEmail(t, "noroles@test.localhost")
	res := client.PutSet(t, uuid.NewString(), withoutRole, helpers.WriteSet{Title: "Nope"})

	assert.Equal(t, http.StatusForbidden, res.StatusCode, res.Text())
}

func TestASetIdMustBeAnId(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "malformed@test.localhost")

	res := client.GetSet(t, "not-a-set-id", token)

	assert.Lessf(t, res.StatusCode, http.StatusInternalServerError,
		"a malformed set id should not be a server error, got %d: %s", res.StatusCode, res.Text())
}

func TestAnUnknownSetIsNotFound(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "unknown@test.localhost")

	assert.Equal(t, http.StatusNotFound, client.GetSet(t, uuid.NewString(), token).StatusCode)
}

func TestUnsupportedMethodsOnSetsAreRejected(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "methods@test.localhost")

	for _, tt := range []struct {
		method string
		path   string
	}{
		{method: http.MethodPost, path: "/sets/" + uuid.NewString()},
		{method: http.MethodPost, path: "/sets"},
		{method: http.MethodPut, path: "/sets"},
		{method: http.MethodDelete, path: "/sets"},
	} {
		t.Run(tt.method+" "+tt.path, func(t *testing.T) {
			res := client.Do(t, helpers.Request{Method: tt.method, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusMethodNotAllowed, res.StatusCode,
				"%s %s should not be allowed: %s", tt.method, tt.path, res.Text())
		})
	}
}

func TestABodyThatIsNotASetIsRejected(t *testing.T) {
	client := harness.EnsureScoresClient(t)
	token := aPlayer(t, "garbage@test.localhost")

	res := client.Do(t, helpers.Request{
		Method:      http.MethodPut,
		Path:        "/sets/" + uuid.NewString(),
		Token:       token,
		ContentType: "application/json",
		Body:        "not json at all",
	})

	assert.Equal(t, http.StatusBadRequest, res.StatusCode, res.Text())
}

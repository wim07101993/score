//go:build integration

package integration_test

import (
	"fmt"
	"net/http"
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

// player is a client together with the address it is calling as, which is what
// a set is shared by.
type player struct {
	*helpers.ApiClient
	Email string
}

// aPlayer is a user who may look at scores and build sets.
//
// Every player gets a scope of its own: who a client is calling as is scoped,
// so two players built from one scope would turn out to be one caller.
func aPlayer(t *testing.T) player {
	t.Helper()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")

	user := helpers.User{Email: uuid.NewString() + "@test.localhost"}
	client.Security.Token = idp.IssueTokenFor(t, user, auth.RoleScoreViewer)

	return player{ApiClient: client, Email: user.Email}
}

// aScore uploads a score for a set to point at and answers its id. Uploading
// takes the editor role, which a player deliberately does not have.
func aScore(t *testing.T) uuid.UUID {
	t.Helper()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")
	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlWithWorkAndMovement)
	return scoreId
}

// ---------------------------------------------------------------------------
// A SET IS A RUNNING ORDER
// ---------------------------------------------------------------------------

func TestCreatingASetStoresWhatWasGiven(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	write := helpers.WriteSetOf("Zomerbar 12 juli", nil, nil)
	write.Description = "outside, two sets of 45"
	helpers.MustPutSet(t, owner.ApiClient, setId, write)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, setId, saved.ID)
	assert.Equal(t, "Zomerbar 12 juli", saved.Title)
	assert.Equal(t, "outside, two sets of 45", saved.Description)
	assert.True(t, saved.IsOwner, "the user who created a set owns it")
	assert.True(t, saved.DeletedAt.Null, "a set that was just created is not deleted")
	assert.NotNil(t, saved.Entries, "entries should be an empty list, never null")
	assert.NotNil(t, saved.SharedWith, "shared_with should be an empty list, never null")
}

// The order of a set is the order of the gig, so it is kept exactly as it was
// given rather than in whatever order the database finds convenient.
func TestASetIsPlayedInTheOrderItWasGivenIn(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second, third := aScore(t), aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Running order",
		[]api.SetEntry{helpers.AnEntry(third), helpers.AnEntry(first), helpers.AnEntry(second)}, nil))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, []uuid.UUID{third, first, second}, helpers.ScoreIdsOf(saved))
}

func TestReorderingASetIsSavedAsTheNewOrder(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second := aScore(t), aScore(t)
	firstEntry, secondEntry := helpers.AnEntry(first), helpers.AnEntry(second)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Before", []api.SetEntry{firstEntry, secondEntry}, nil))
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("After", []api.SetEntry{secondEntry, firstEntry}, nil))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, []uuid.UUID{second, first}, helpers.ScoreIdsOf(saved))
	assert.Equal(t, "After", saved.Title)
}

// A song can come round twice in a gig, and the second time is its own entry:
// its own place in the order, its own note, and its own key.
func TestTheSameScoreCanBePlayedTwiceInASet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	opener := api.SetEntry{
		ID: uuid.New(), ScoreID: scoreId,
		Description: "opener, full band", Transposition: 0, HiddenParts: []string{},
	}
	encore := api.SetEntry{
		ID: uuid.New(), ScoreID: scoreId,
		Description: "encore, voice only", Transposition: -2, HiddenParts: []string{"P2"},
	}

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Twice round",
		[]api.SetEntry{opener, helpers.AnEntry(aScore(t)), encore}, nil))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 3)
	assert.Equal(t, scoreId, saved.Entries[0].ScoreID)
	assert.Equal(t, scoreId, saved.Entries[2].ScoreID)

	assert.Equal(t, "opener, full band", saved.Entries[0].Description)
	assert.Equal(t, 0, saved.Entries[0].Transposition)
	assert.Empty(t, saved.Entries[0].HiddenParts)

	assert.Equal(t, "encore, voice only", saved.Entries[2].Description)
	assert.Equal(t, -2, saved.Entries[2].Transposition, "the two times round are played in different keys")
	assert.Equal(t, []string{"P2"}, saved.Entries[2].HiddenParts)
}

// ---------------------------------------------------------------------------
// HOW A SCORE IS PLAYED IN THIS SET
// ---------------------------------------------------------------------------

// The key and the parts on screen are what the player needs back when they open
// a score from inside a set, so they have to survive the round trip exactly.
func TestHowAScoreIsPlayedIsKeptWithTheSet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Arrangements",
		[]api.SetEntry{{
			ID:            uuid.New(),
			ScoreID:       scoreId,
			Description:   "down a third for the singer",
			Transposition: -4,
			HiddenParts:   []string{"P2", "P3"},
		}}, nil))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 1)
	assert.Equal(t, -4, saved.Entries[0].Transposition)
	assert.Equal(t, []string{"P2", "P3"}, saved.Entries[0].HiddenParts)
	assert.Equal(t, "down a third for the singer", saved.Entries[0].Description)
}

// Playing a score in another key is a property of the set, not of the score.
func TestPlayingAScoreInAnotherKeyLeavesTheScoreAlone(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	editor := helpers.Ensure(t, h.ApiClient, "ApiClient")
	editor.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, editor, scoreId, helpers.MusicXmlWithWorkAndMovement)

	helpers.MustPutSet(t, owner.ApiClient, uuid.New(), helpers.WriteSetOf("Transposed",
		[]api.SetEntry{{
			ID: uuid.New(), ScoreID: scoreId, Transposition: 5, HiddenParts: []string{},
		}}, nil))

	document := mustGetScoreDocument(t, editor, scoreId, helpers.MusicXmlContentType)
	assert.Equal(t, helpers.MusicXmlWithWorkAndMovement, document,
		"putting a score in a set changed the score itself")
}

func TestASetRefusesATranspositionItCannotPlay(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	// Sent by hand rather than through the generated client: the range is in
	// the spec, so the client would refuse to send it and the server would
	// never get to say no. What this is about is the server saying no.
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")

	for _, semitones := range []int{13, -13, 200} {
		body := fmt.Sprintf(
			`{"title":"Out of range","description":"","shared_with":[],"entries":[
				{"id":%q,"score_id":%q,"description":"","transposition":%d,"hidden_parts":[]}]}`,
			uuid.NewString(), scoreId, semitones)

		res := raw.Do(t, helpers.Request{
			Method:      http.MethodPut,
			Path:        "/sets/" + uuid.NewString(),
			Token:       tokenOf(t, owner),
			ContentType: "application/json",
			Body:        body,
		})

		assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
			"a transposition of %d semitones should be refused: %s", semitones, res.Text())
	}
}

func TestASetRefusesAScoreThatDoesNotExist(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	res, err := owner.PutSet(t.Context(),
		helpers.WriteSetOf("Ghost", []api.SetEntry{helpers.AnEntry(uuid.New())}, nil),
		api.PutSetParams{SetId: setId})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutSetBadRequest)
	require.Truef(t, ok, "a set naming a score that does not exist should be refused, got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeUnknownScore, badRequest.ErrorCode)

	got, err := owner.GetSet(t.Context(), api.GetSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetSetNotFound{}, got, "a refused set should not have been stored, got %#v", got)
}

func TestASetRefusesTheSameEntryTwice(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	entry := helpers.AnEntry(aScore(t))

	res, err := owner.PutSet(t.Context(),
		helpers.WriteSetOf("Duplicate", []api.SetEntry{entry, entry}, nil),
		api.PutSetParams{SetId: uuid.New()})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutSetBadRequest)
	require.Truef(t, ok, "two entries with the same id should be refused, got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeInvalidSet, badRequest.ErrorCode)
}

// ---------------------------------------------------------------------------
// A SET BELONGS TO SOMEBODY
// ---------------------------------------------------------------------------

func TestASetIsNotVisibleToEveryone(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Private", nil, nil))

	res, err := stranger.GetSet(t.Context(), api.GetSetParams{SetId: setId})

	require.NoError(t, err)
	notFound, ok := res.(*api.GetSetNotFound)
	require.Truef(t, ok, "a set someone has nothing to do with should not be readable, got %#v", res)
	assert.NotContains(t, notFound.Detail, "Private", "the title of another user's set leaked")
}

func TestListingSetsOnlyShowsYourOwn(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Mine", nil, nil))

	window := api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()}

	mine := helpers.MustListSets(t, owner.ApiClient, window)
	_, found := helpers.FindSet(mine, setId)
	assert.True(t, found, "a set should be in its owner's list")

	theirs := helpers.MustListSets(t, stranger.ApiClient, window)
	_, found = helpers.FindSet(theirs, setId)
	assert.False(t, found, "another user's set should not be in the list")
}

func TestOnlyTheOwnerCanChangeASet(t *testing.T) {
	t.Parallel()

	owner, meddler := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Kept", nil, nil))

	res, err := meddler.PutSet(t.Context(),
		helpers.WriteSetOf("Meddled with", nil, nil),
		api.PutSetParams{SetId: setId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetForbidden{}, res, "got %#v", res)
	assert.Equal(t, "Kept", helpers.MustGetSet(t, owner.ApiClient, setId).Title,
		"a set was changed by someone who does not own it")
}

// ---------------------------------------------------------------------------
// SHARING
// ---------------------------------------------------------------------------

func TestASharedSetCanBeReadByThePersonItIsSharedWith(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Friday night",
		[]api.SetEntry{{
			ID: uuid.New(), ScoreID: scoreId,
			Transposition: 2, Description: "count it in", HiddenParts: []string{},
		}},
		[]string{bandMember.Email}))

	shared := helpers.MustGetSet(t, bandMember.ApiClient, setId)

	assert.Equal(t, "Friday night", shared.Title)
	assert.False(t, shared.IsOwner, "a set someone shared is not theirs")
	require.Len(t, shared.Entries, 1)
	assert.Equal(t, 2, shared.Entries[0].Transposition, "the band should see the key the set is played in")
	assert.Equal(t, "count it in", shared.Entries[0].Description)
}

func TestASharedSetIsInTheListOfThePersonItIsSharedWith(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Saturday night", nil, []string{bandMember.Email}))

	sets := helpers.MustListSets(t, bandMember.ApiClient,
		api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})

	found, ok := helpers.FindSet(sets, setId)
	require.True(t, ok, "a shared set should be in the list of the person it is shared with")
	assert.False(t, found.IsOwner)
}

// Sharing is by address, and an address that differs only in case is the same
// address: nobody types their email the same way twice.
func TestSharingIgnoresTheCaseOfAnAddress(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Case", nil, []string{strings.ToUpper(bandMember.Email)}))

	assert.Equal(t, "Case", helpers.MustGetSet(t, bandMember.ApiClient, setId).Title)
}

// Sharing is for reading. A band member seeing the set is not a band member
// rewriting it.
func TestSharingASetDoesNotAllowChangingIt(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Read only", nil, []string{bandMember.Email}))

	write, err := bandMember.PutSet(t.Context(),
		helpers.WriteSetOf("Rewritten", nil, nil),
		api.PutSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetForbidden{}, write, "got %#v", write)

	// Deleting is 404 rather than 403: only the owner deletes, and to everyone
	// else a set they cannot delete is a set that is not there.
	remove, err := bandMember.DeleteSet(t.Context(), api.DeleteSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.DeleteSetNotFound{}, remove,
		"a shared set is not the reader's to delete, got %#v", remove)

	assert.Equal(t, "Read only", helpers.MustGetSet(t, owner.ApiClient, setId).Title)
}

// Who else a set is shared with is the owner's business.
func TestThePeopleASetIsSharedWithAreOnlyShownToTheOwner(t *testing.T) {
	t.Parallel()

	owner, singer, trumpet := aPlayer(t), aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Who else", nil, []string{singer.Email, trumpet.Email}))

	asOwner := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.ElementsMatch(t, []string{singer.Email, trumpet.Email}, asOwner.SharedWith)

	asReader := helpers.MustGetSet(t, singer.ApiClient, setId)
	assert.Empty(t, asReader.SharedWith, "a reader should not learn who else has the set")
	assert.NotContains(t, asReader.SharedWith, trumpet.Email, "another band member's address leaked")
}

func TestUnsharingASetTakesItAway(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Shared for now", nil, []string{bandMember.Email}))
	require.Equal(t, "Shared for now", helpers.MustGetSet(t, bandMember.ApiClient, setId).Title)

	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Shared for now", nil, nil))

	res, err := bandMember.GetSet(t.Context(), api.GetSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetSetNotFound{}, res,
		"a set that is no longer shared should no longer be readable, got %#v", res)
}

// ---------------------------------------------------------------------------
// SYNCING BETWEEN DEVICES
// ---------------------------------------------------------------------------

// A set is edited offline and synced afterwards, so a set deleted on one device
// has to be recognisable as deleted by another that still has it. Dropping the
// row would leave the other device with a set nothing ever contradicts.
func TestADeletedSetIsReportedAsDeletedRatherThanVanishing(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Cancelled gig", nil, nil))
	mustDeleteSet(t, owner.ApiClient, setId)

	sets := helpers.MustListSets(t, owner.ApiClient,
		api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})
	deleted, found := helpers.FindSet(sets, setId)

	require.True(t, found, "a deleted set should still be reported so other devices drop it")
	assert.False(t, deleted.DeletedAt.Null, "the set is not marked as deleted")
}

func TestADeletedSetCannotBeReadAnyMore(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Gone", nil, nil))
	mustDeleteSet(t, owner.ApiClient, setId)

	res, err := owner.GetSet(t.Context(), api.GetSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetSetNotFound{}, res, "a deleted set should not be readable, got %#v", res)

	again, err := owner.DeleteSet(t.Context(), api.DeleteSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.DeleteSetNotFound{}, again,
		"deleting a set that is already gone is not a server error, got %#v", again)
}

// A device that has been offline can still be holding a set that was deleted
// elsewhere. Editing it says the set should exist again, which is the only way
// back for a set that was deleted by mistake.
func TestWritingADeletedSetAgainBringsItBack(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Cancelled", nil, nil))
	mustDeleteSet(t, owner.ApiClient, setId)

	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Back on", nil, nil))

	revived := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, "Back on", revived.Title)
	assert.True(t, revived.DeletedAt.Null)
}

// A device that was offline while a set was edited should get it on its next
// sync, which is what the change window is for.
func TestOnlyTheSetsChangedInTheWindowAreListed(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Recent", nil, nil))

	inWindow := helpers.MustListSets(t, owner.ApiClient,
		api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})
	_, found := helpers.FindSet(inWindow, setId)
	assert.True(t, found, "a set changed just now should be in a window that covers now")

	beforeWindow := helpers.MustListSets(t, owner.ApiClient, api.ListSetsParams{
		ChangesSince: time.Now().Add(-48 * time.Hour),
		ChangesUntil: time.Now().Add(-24 * time.Hour),
	})
	_, found = helpers.FindSet(beforeWindow, setId)
	assert.False(t, found, "a set changed today is not in a window that ended yesterday")
}

func TestListingSetsRequiresAChangeWindow(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")
	token := tokenOf(t, owner)

	tests := []struct {
		name string
		path string
	}{
		{name: "no parameters", path: "/sets"},
		{name: "only Changes-Since", path: "/sets?Changes-Since=2024-01-01T00:00:00Z"},
		{name: "only Changes-Until", path: "/sets?Changes-Until=2024-01-01T00:00:00Z"},
		{name: "malformed Changes-Since", path: "/sets?Changes-Since=yesterday&Changes-Until=2024-01-01T00:00:00Z"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			res := raw.Do(t, helpers.Request{Method: http.MethodGet, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
				"listing sets with %s should be rejected: %s", tt.name, res.Text())
		})
	}
}

// ---------------------------------------------------------------------------
// THE REST OF THE ENDPOINT
// ---------------------------------------------------------------------------

func TestSetsRequireAValidToken(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")
	setId := uuid.NewString()

	for _, tt := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "reading one", method: http.MethodGet, path: "/sets/" + setId},
		{name: "listing", method: http.MethodGet, path: "/sets?Changes-Since=2024-01-01T00:00:00Z&Changes-Until=2024-01-01T00:00:00Z"},
		{name: "writing", method: http.MethodPut, path: "/sets/" + setId},
		{name: "deleting", method: http.MethodDelete, path: "/sets/" + setId},
	} {
		t.Run(tt.name, func(t *testing.T) {
			res := raw.Do(t, helpers.Request{Method: tt.method, Path: tt.path})
			assert.Equal(t, http.StatusUnauthorized, res.StatusCode, res.Text())
		})
	}
}

// A set names scores and changes nothing about them, so building one asks no
// more of a user than reading the scores in it.
func TestSetsRequireTheViewerRole(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")
	client.Security.Token = idp.IssueToken(t)

	res, err := client.PutSet(t.Context(),
		helpers.WriteSetOf("Nope", nil, nil),
		api.PutSetParams{SetId: uuid.New()})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetForbidden{}, res, "got %#v", res)
}

func TestASetIdMustBeAnId(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")

	res := raw.Do(t, helpers.Request{
		Method: http.MethodGet,
		Path:   "/sets/not-a-set-id",
		Token:  tokenOf(t, owner),
	})

	assert.Lessf(t, res.StatusCode, http.StatusInternalServerError,
		"a malformed set id should not be a server error, got %d: %s", res.StatusCode, res.Text())
}

func TestAnUnknownSetIsNotFound(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	res, err := owner.GetSet(t.Context(), api.GetSetParams{SetId: uuid.New()})

	require.NoError(t, err)
	assert.IsTypef(t, &api.GetSetNotFound{}, res, "got %#v", res)
}

func TestUnsupportedMethodsOnSetsAreRejected(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")
	token := tokenOf(t, owner)

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
			res := raw.Do(t, helpers.Request{Method: tt.method, Path: tt.path, Token: token})

			assert.Equalf(t, http.StatusMethodNotAllowed, res.StatusCode,
				"%s %s should not be allowed: %s", tt.method, tt.path, res.Text())
		})
	}
}

func TestABodyThatIsNotASetIsRejected(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")

	res := raw.Do(t, helpers.Request{
		Method:      http.MethodPut,
		Path:        "/sets/" + uuid.NewString(),
		Token:       tokenOf(t, owner),
		ContentType: "application/json",
		Body:        "not json at all",
	})

	assert.Equal(t, http.StatusBadRequest, res.StatusCode, res.Text())
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

func mustDeleteSet(t *testing.T, client *helpers.ApiClient, setId uuid.UUID) {
	t.Helper()

	res, err := client.DeleteSet(t.Context(), api.DeleteSetParams{SetId: setId})
	require.NoErrorf(t, err, "failed to delete set %s", setId)
	require.IsTypef(t, &api.DeleteSetNoContent{}, res, "failed to delete set %s: %#v", setId, res)
}

// tokenOf is the token a player calls with, for the tests that reach past the
// generated client and build a request by hand.
func tokenOf(t *testing.T, p player) string {
	t.Helper()
	return p.Security.Token
}

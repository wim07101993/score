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
	write := helpers.WriteSetOf("Zomerbar 12 juli", nil)
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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Running order", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, third, first, second)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, []uuid.UUID{third, first, second}, helpers.ScoreIdsOf(saved))
	assert.Equal(t, []int{0, 1, 2}, positionsOf(saved),
		"the places should be nought upwards with no gaps in them")
}

// An entry written at a place the set already has an entry in puts that one and
// everything after it back by one.
func TestAnEntryPutInTheMiddleOfASetPushesTheRestBack(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second, squeezedIn := aScore(t), aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Squeeze", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, first, second)

	saved := helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(),
		helpers.AnEntry(squeezedIn, 1))

	assert.Equal(t, 1, saved.Position, "the entry should be handed back where it ended up")
	set := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, []uuid.UUID{first, squeezedIn, second}, helpers.ScoreIdsOf(set))
	assert.Equal(t, []int{0, 1, 2}, positionsOf(set))
}

// A client catching up after a gig it spent offline is saying where a song
// goes, and the nearest place it can go is a better answer than a refusal.
func TestAnEntryPutPastTheEndOfASetGoesAtTheEnd(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, late := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Past the end", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, first)

	saved := helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), helpers.AnEntry(late, 99))

	assert.Equal(t, 1, saved.Position)
	assert.Equal(t, []uuid.UUID{first, late},
		helpers.ScoreIdsOf(helpers.MustGetSet(t, owner.ApiClient, setId)))
}

func TestTakingAnEntryOutOfASetClosesTheOrderUp(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second, third := aScore(t), aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Dropped", nil))
	entries := helpers.MustFillSet(t, owner.ApiClient, setId, first, second, third)

	helpers.MustDeleteEntry(t, owner.ApiClient, setId, entries[0].ID)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, []uuid.UUID{second, third}, helpers.ScoreIdsOf(saved))
	assert.Equal(t, []int{0, 1}, positionsOf(saved), "the set was left with a gap in it")
}

func TestReorderingASetIsSavedAsTheNewOrder(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Before", nil))
	entries := helpers.MustFillSet(t, owner.ApiClient, setId, first, second)

	// Moving one song is writing that one song, at the place it moves to.
	moved := helpers.TheSameEntry(*entries[1])
	moved.Position = 0
	helpers.MustPutEntry(t, owner.ApiClient, setId, entries[1].ID, moved)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, []uuid.UUID{second, first}, helpers.ScoreIdsOf(saved))
	assert.Equal(t, []int{0, 1}, positionsOf(saved))
	assert.Equal(t, entries[1].ID, saved.Entries[0].ID, "a song that moved was given a new id")
}

// A song can come round twice in a gig, and the second time is its own entry:
// its own place in the order, its own note, and its own key.
func TestTheSameScoreCanBePlayedTwiceInASet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	opener := &api.WriteSetEntry{
		ScoreID:     api.NewNilUUID(scoreId),
		Description: "opener, full band", Transposition: 0, Position: 0,
	}
	encore := &api.WriteSetEntry{
		ScoreID:     api.NewNilUUID(scoreId),
		Description: "encore, down a tone", Transposition: -2, Position: 2,
	}

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Twice round", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), opener)
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), helpers.AnEntry(aScore(t), 1))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), encore)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 3)
	assert.Equal(t, scoreId, saved.Entries[0].ScoreID.Value)
	assert.Equal(t, scoreId, saved.Entries[2].ScoreID.Value)

	assert.Equal(t, "opener, full band", saved.Entries[0].Description)
	assert.Equal(t, 0, saved.Entries[0].Transposition)

	assert.Equal(t, "encore, down a tone", saved.Entries[2].Description)
	assert.Equal(t, -2, saved.Entries[2].Transposition, "the two times round are played in different keys")

	assert.NotEqual(t, saved.Entries[0].ID, saved.Entries[2].ID,
		"the same score twice is two entries, and each carries its own views")
}

// ---------------------------------------------------------------------------
// HOW A SCORE IS PLAYED IN THIS SET
// ---------------------------------------------------------------------------

// The key the band plays a song in is what every player needs back when they
// open it from inside a set, so it has to survive the round trip exactly.
func TestTheKeyTheBandPlaysInIsKeptWithTheSet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Arrangements", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), &api.WriteSetEntry{
		ScoreID:       api.NewNilUUID(scoreId),
		Description:   "down a third for the singer",
		Transposition: -4,
	})

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 1)
	assert.Equal(t, -4, saved.Entries[0].Transposition)
	assert.Equal(t, "down a third for the singer", saved.Entries[0].Description)

	// Nobody has said anything about how they look at it, which is the view
	// every entry starts with: as written, every part on screen.
	assert.Equal(t, 0, saved.Entries[0].View.Transposition)
	assert.Empty(t, saved.Entries[0].View.HiddenParts)
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

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Transposed", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), &api.WriteSetEntry{
		ScoreID: api.NewNilUUID(scoreId), Transposition: 5,
	})

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

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Out of range", nil))

	for _, semitones := range []int{13, -13, 200} {
		body := fmt.Sprintf(
			`{"score_id":%q,"description":"","transposition":%d,"position":0}`,
			scoreId, semitones)

		res := raw.Do(t, helpers.Request{
			Method:      http.MethodPut,
			Path:        fmt.Sprintf("/sets/%s/entries/%s", setId, uuid.NewString()),
			Token:       tokenOf(t, owner),
			ContentType: "application/json",
			Body:        body,
		})

		assert.Equalf(t, http.StatusBadRequest, res.StatusCode,
			"a transposition of %d semitones should be refused: %s", semitones, res.Text())
	}

	assert.Empty(t, helpers.MustGetSet(t, owner.ApiClient, setId).Entries,
		"a refused entry should not have been stored")
}

// A place before the start of a set is not a place. Past the end is, and is the
// end of the set; there is no such forgiving reading of a negative one.
func TestAnEntryRefusesAPlaceBeforeTheStartOfTheSet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Before the start", nil))

	res := raw.Do(t, helpers.Request{
		Method:      http.MethodPut,
		Path:        fmt.Sprintf("/sets/%s/entries/%s", setId, uuid.NewString()),
		Token:       tokenOf(t, owner),
		ContentType: "application/json",
		Body:        fmt.Sprintf(`{"score_id":%q,"description":"","transposition":0,"position":-1}`, scoreId),
	})

	assert.Equal(t, http.StatusBadRequest, res.StatusCode, res.Text())
}

func TestASetRefusesAScoreThatDoesNotExist(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Ghost", nil))

	res, err := owner.PutSetEntry(t.Context(), helpers.AnEntry(uuid.New(), 0),
		api.PutSetEntryParams{SetId: setId, EntryId: uuid.New()})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutSetEntryBadRequest)
	require.Truef(t, ok, "an entry naming a score that does not exist should be refused, got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeUnknownScore, badRequest.ErrorCode)

	assert.Empty(t, helpers.MustGetSet(t, owner.ApiClient, setId).Entries,
		"a refused entry should not have been stored")
}

// Two entries a client cannot tell apart are still two entries. Nothing about
// an entry says which row it is, so there is nothing for the second one to
// collide with.
func TestTwoIdenticalEntriesAreKeptAsTwo(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Twice", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), helpers.AnEntry(scoreId, 0))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), helpers.AnEntry(scoreId, 1))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 2)
	assert.NotEqual(t, saved.Entries[0].ID, saved.Entries[1].ID,
		"each entry should have been stored under an id of its own")
}

// An entry a client names keeps that id, which is what lets a client that made
// an entry up while it had no network say how it looks at it before the entry
// has ever reached the server.
func TestAnEntryTheClientNamedKeepsThatId(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	named := uuid.New()
	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Named", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, named, helpers.AnEntry(scoreId, 0))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 1)
	assert.Equal(t, named, saved.Entries[0].ID)
}

// ---------------------------------------------------------------------------
// A SET BELONGS TO SOMEBODY
// ---------------------------------------------------------------------------

func TestASetIsNotVisibleToEveryone(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Private", nil))

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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Mine", nil))

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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Kept", nil))

	res, err := meddler.PutSet(t.Context(),
		helpers.WriteSetOf("Meddled with", nil),
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
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday night", []string{bandMember.Email}))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), &api.WriteSetEntry{
		ScoreID:       api.NewNilUUID(scoreId),
		Transposition: 2, Description: "count it in",
	})

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
		helpers.WriteSetOf("Saturday night", []string{bandMember.Email}))

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
		helpers.WriteSetOf("Case", []string{strings.ToUpper(bandMember.Email)}))

	assert.Equal(t, "Case", helpers.MustGetSet(t, bandMember.ApiClient, setId).Title)
}

// Sharing is for reading. A band member seeing the set is not a band member
// rewriting it.
func TestSharingASetDoesNotAllowChangingIt(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Read only", []string{bandMember.Email}))

	write, err := bandMember.PutSet(t.Context(),
		helpers.WriteSetOf("Rewritten", nil),
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
		helpers.WriteSetOf("Who else", []string{singer.Email, trumpet.Email}))

	asOwner := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.ElementsMatch(t, []string{singer.Email, trumpet.Email}, asOwner.SharedWith)

	asReader := helpers.MustGetSet(t, singer.ApiClient, setId)
	assert.Empty(t, asReader.SharedWith, "a reader should not learn who else has the set")

	// Read back as bytes as well as as a set, and on both endpoints. An address
	// that never reaches the parsed field can still be somewhere else in the
	// body, and a set is served by the listing as well as one at a time — the
	// share list is filled in by one query behind both, so a leak would be a
	// leak in both.
	h := harness.NewScope()
	raw := helpers.Ensure(t, h.RawClient, "RawClient")
	readerToken := tokenOf(t, singer)

	one := raw.Do(t, helpers.Request{
		Method: http.MethodGet,
		Path:   "/sets/" + setId.String(),
		Token:  readerToken,
	})
	require.Equal(t, http.StatusOK, one.StatusCode, one.Text())

	list := raw.Do(t, helpers.Request{
		Method: http.MethodGet,
		Path:   "/sets?Changes-Since=2000-01-01T00:00:00Z&Changes-Until=2100-01-01T00:00:00Z",
		Token:  readerToken,
	})
	require.Equal(t, http.StatusOK, list.StatusCode, list.Text())

	for _, res := range []helpers.Response{one, list} {
		assert.NotContains(t, res.Text(), trumpet.Email,
			"another band member's address leaked: %s", res.Text())
		assert.NotContains(t, res.Text(), singer.Email,
			"a reader was told they are on the share list: %s", res.Text())
	}
}

func TestUnsharingASetTakesItAway(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Shared for now", []string{bandMember.Email}))
	require.Equal(t, "Shared for now", helpers.MustGetSet(t, bandMember.ApiClient, setId).Title)

	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Shared for now", nil))

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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Cancelled gig", nil))
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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Gone", nil))
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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Cancelled", nil))
	mustDeleteSet(t, owner.ApiClient, setId)

	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Back on", nil))

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
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Recent", nil))

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
		helpers.WriteSetOf("Nope", nil),
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
// WHAT ONE PLAYER LOOKS AT
// ---------------------------------------------------------------------------

// The whole of it: a set says what the band plays, and how one player reads it
// is nobody else's business. The saxophone player wants their part a sixth up
// and the vocals next to it; the pianist wants the piano staff alone, in the
// key it is written in. Both are looking at the same entry of the same set.
func TestTwoPlayersLookAtTheSameEntryTheirOwnWay(t *testing.T) {
	t.Parallel()

	sax, pianist := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, sax.ApiClient, setId,
		helpers.WriteSetOf("Zomerbar", []string{pianist.Email}))
	entryId := helpers.MustPutEntry(t, sax.ApiClient, setId, uuid.New(), &api.WriteSetEntry{
		ScoreID: api.NewNilUUID(scoreId), Transposition: -2, Description: "count it in",
	}).ID

	helpers.MustPutEntryView(t, sax.ApiClient, setId, entryId, helpers.AView(9, "P3"))
	helpers.MustPutEntryView(t, pianist.ApiClient, setId, entryId, helpers.AView(0, "P1", "P2"))

	asTheSaxSeesIt := helpers.MustGetSet(t, sax.ApiClient, setId)
	asThePianistSeesIt := helpers.MustGetSet(t, pianist.ApiClient, setId)

	assert.Equal(t, 9, asTheSaxSeesIt.Entries[0].View.Transposition)
	assert.Equal(t, []string{"P3"}, asTheSaxSeesIt.Entries[0].View.HiddenParts)

	assert.Equal(t, 0, asThePianistSeesIt.Entries[0].View.Transposition,
		"the pianist was handed the key the saxophone player reads in")
	assert.Equal(t, []string{"P1", "P2"}, asThePianistSeesIt.Entries[0].View.HiddenParts,
		"the pianist was handed the parts the saxophone player has off screen")

	// What the band does is the same for both of them.
	assert.Equal(t, -2, asTheSaxSeesIt.Entries[0].Transposition)
	assert.Equal(t, -2, asThePianistSeesIt.Entries[0].Transposition)
	assert.Equal(t, "count it in", asThePianistSeesIt.Entries[0].Description)
}

// Writing a view is not writing the set, so it asks no more of a player than
// reading the set does. A band member who cannot change a note of the running
// order can still say how they read it.
func TestSomeoneASetIsSharedWithWritesTheirOwnViewButNotTheSet(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Kept", []string{bandMember.Email}))
	entryId := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0].ID

	saved := helpers.MustPutEntryView(t, bandMember.ApiClient, setId, entryId, helpers.AView(-3, "P2"))
	assert.Equal(t, -3, saved.Transposition)

	// The set itself is the owner's, and a view changed nothing about it.
	res, err := bandMember.PutSet(t.Context(),
		helpers.WriteSetOf("Renamed", nil),
		api.PutSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetForbidden{}, res, "got %#v", res)

	asTheOwnerSeesIt := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, "Kept", asTheOwnerSeesIt.Title)
	assert.Equal(t, 0, asTheOwnerSeesIt.Entries[0].View.Transposition,
		"the owner was handed the view somebody else wrote")
}

// The reason an entry keeps its id across a write: what the players said about
// how they look at it hangs off that id, and an owner tidying up the running
// order should not throw the band's reading of it away.
func TestRewritingASetLeavesEveryPlayersViewAlone(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	first, second := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday", []string{bandMember.Email}))
	helpers.MustFillSet(t, owner.ApiClient, setId, first, second)

	before := helpers.MustGetSet(t, owner.ApiClient, setId)
	helpers.MustPutEntryView(t, bandMember.ApiClient, setId, before.Entries[0].ID, helpers.AView(9, "P2"))

	// The owner renames the set and changes a note on the first song.
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday, second version", []string{bandMember.Email}))
	changed := helpers.TheSameEntry(before.Entries[0])
	changed.Description = "straight into the next"
	helpers.MustPutEntry(t, owner.ApiClient, setId, before.Entries[0].ID, changed)

	after := helpers.MustGetSet(t, bandMember.ApiClient, setId)

	require.Len(t, after.Entries, 2)
	assert.Equal(t, before.Entries[0].ID, after.Entries[0].ID, "an entry that stayed was given a new id")
	assert.Equal(t, "straight into the next", after.Entries[0].Description)
	assert.Equal(t, 9, after.Entries[0].View.Transposition,
		"writing the entry threw away how a player reads it")
	assert.Equal(t, []string{"P2"}, after.Entries[0].View.HiddenParts)
}

// Swapping two entries has both of them wanting the place the other is in, for
// as long as the write takes.
func TestReorderingASetKeepsTheEntriesAndTheirViews(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Before", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, first, second)

	before := helpers.MustGetSet(t, owner.ApiClient, setId)
	helpers.MustPutEntryView(t, owner.ApiClient, setId, before.Entries[1].ID, helpers.AView(-5))

	moved := helpers.TheSameEntry(before.Entries[1])
	moved.Position = 0
	helpers.MustPutEntry(t, owner.ApiClient, setId, before.Entries[1].ID, moved)

	after := helpers.MustGetSet(t, owner.ApiClient, setId)

	assert.Equal(t, []uuid.UUID{second, first}, helpers.ScoreIdsOf(after))
	assert.Equal(t, before.Entries[1].ID, after.Entries[0].ID)
	assert.Equal(t, -5, after.Entries[0].View.Transposition,
		"a view should follow the entry it belongs to rather than the place it was in")
	assert.Equal(t, 0, after.Entries[1].View.Transposition)
}

// An entry that is out of the set is out of it: what the players said about how
// they looked at it was about a song that is no longer played.
func TestAnEntryTakenOutOfASetTakesTheViewsOfItAlong(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Friday", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)

	before := helpers.MustGetSet(t, owner.ApiClient, setId)
	helpers.MustPutEntryView(t, owner.ApiClient, setId, before.Entries[0].ID, helpers.AView(7, "P2"))

	// Taken out, and the same song put back as a new entry.
	helpers.MustDeleteEntry(t, owner.ApiClient, setId, before.Entries[0].ID)
	helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)

	after := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, after.Entries, 1)
	assert.NotEqual(t, before.Entries[0].ID, after.Entries[0].ID)
	assert.Equal(t, 0, after.Entries[0].View.Transposition,
		"a new entry started life with somebody's view of the one it replaced")
	assert.Empty(t, after.Entries[0].View.HiddenParts)
}

// A sync asks for everything that changed for the caller since it last asked.
// A view is a change to the set for the player who wrote it — it is what their
// other devices have to learn about — and no change at all for anybody else.
func TestAViewChangesTheSetForThePlayerWhoWroteItAndNobodyElse(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Windows", []string{bandMember.Email}))
	entryId := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0].ID

	// A moment after the set was written and before the view is, and a whole
	// second at that: a window is asked for as an RFC 3339 moment, which carries
	// no fraction of a second, so a start inside the second the set was written
	// in arrives as a start before it.
	between := time.Now().Add(time.Second).Truncate(time.Second)
	time.Sleep(time.Until(between) + 10*time.Millisecond)

	helpers.MustPutEntryView(t, bandMember.ApiClient, setId, entryId, helpers.AView(9))

	forTheBandMember := helpers.MustListSets(t, bandMember.ApiClient,
		api.ListSetsParams{ChangesSince: between, ChangesUntil: soon()})
	_, inTheirWindow := helpers.FindSet(forTheBandMember, setId)
	assert.True(t, inTheirWindow,
		"a player's own view should reach their other devices, and a sync only asks about what changed")

	forTheOwner := helpers.MustListSets(t, owner.ApiClient,
		api.ListSetsParams{ChangesSince: between, ChangesUntil: soon()})
	_, inTheOwnersWindow := helpers.FindSet(forTheOwner, setId)
	assert.False(t, inTheOwnersWindow,
		"somebody else's view was handed to the owner as a change to their set")
}

// How big a player draws a score is theirs the way the key they read it in is:
// the one with the tablet on a stand across the room and the one holding a
// phone are looking at the same entry of the same set.
func TestHowBigAPlayerDrawsAScoreIsTheirOwn(t *testing.T) {
	t.Parallel()

	onAStand, onAPhone := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, onAStand.ApiClient, setId,
		helpers.WriteSetOf("Two screens", []string{onAPhone.Email}))
	entryId := helpers.MustFillSet(t, onAStand.ApiClient, setId, scoreId)[0].ID

	saved := helpers.MustPutEntryView(t, onAStand.ApiClient, setId, entryId,
		helpers.AViewAtZoom(0, 2.5, "P2"))
	assert.InDelta(t, 2.5, saved.Zoom, 0.0001, "the size should come back as it was written")

	helpers.MustPutEntryView(t, onAPhone.ApiClient, setId, entryId, helpers.AViewAtZoom(0, 0.75))

	asTheStandSeesIt := helpers.MustGetSet(t, onAStand.ApiClient, setId)
	asThePhoneSeesIt := helpers.MustGetSet(t, onAPhone.ApiClient, setId)

	assert.InDelta(t, 2.5, asTheStandSeesIt.Entries[0].View.Zoom, 0.0001)
	assert.InDelta(t, 0.75, asThePhoneSeesIt.Entries[0].View.Zoom, 0.0001,
		"the phone was handed the size the stand reads at")
}

// An entry nobody has said anything about is drawn the size it is written at,
// and so is one whose view was written by a client that has never heard of
// drawing it any bigger. Such a client is still saying something true about the
// key and the parts, and throwing that away over a field it does not know about
// would lose an edit it made at a gig.
func TestAScoreIsDrawnAsItIsWrittenUntilSomebodySaysOtherwise(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("As written", nil))
	entryId := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0].ID

	neverLookedAt := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.InDelta(t, 1, neverLookedAt.Entries[0].View.Zoom, 0.0001)

	saved := helpers.MustPutEntryView(t, owner.ApiClient, setId, entryId, helpers.AView(3, "P2"))
	assert.InDelta(t, 1, saved.Zoom, 0.0001,
		"a view that says nothing about the size should be read as the size it is written at")

	written := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, 3, written.Entries[0].View.Transposition,
		"what it did say should have been kept")
	assert.InDelta(t, 1, written.Entries[0].View.Zoom, 0.0001)
}

// ---------------------------------------------------------------------------
// SONGS THAT ARE NOT IN HERE
// ---------------------------------------------------------------------------

// Half of what a band plays is on paper. A running order that could only name
// what has been uploaded is not the running order, so an entry may have no
// score: a place in the gig with nothing to open, called by whatever is written
// next to it.
func TestASetHoldsASongThatHasNoScore(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Half on paper", nil))
	helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(), helpers.AnEntry(scoreId, 0))
	onPaper := helpers.MustPutEntry(t, owner.ApiClient, setId, uuid.New(),
		helpers.APaperEntry("Blue Bossa — red folder", 1))

	assert.True(t, onPaper.ScoreID.Null, "the entry should have come back with no score")
	assert.Equal(t, "Blue Bossa — red folder", onPaper.Description)

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 2)
	assert.Equal(t, scoreId, saved.Entries[0].ScoreID.Value)
	assert.False(t, saved.Entries[0].ScoreID.Null)
	assert.True(t, saved.Entries[1].ScoreID.Null)
	assert.Equal(t, "Blue Bossa — red folder", saved.Entries[1].Description)
}

// A song on paper takes its place in the gig like any other, and the songs that
// do have a score close up around it.
func TestASongOnPaperIsPlayedWhereItIsPutInTheRunningOrder(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, last := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Paper in the middle", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, first, last)
	paperId := uuid.New()
	helpers.MustPutEntry(t, owner.ApiClient, setId, paperId, helpers.APaperEntry("the medley", 1))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)

	require.Len(t, saved.Entries, 3)
	assert.Equal(t, []uuid.UUID{first, uuid.Nil, last}, helpers.ScoreIdsOf(saved))
	assert.Equal(t, paperId, saved.Entries[1].ID)
	assert.Equal(t, []int{0, 1, 2}, positionsOf(saved))

	// And it can be given a score later, when somebody gets round to uploading
	// it: it is the same song in the same place in the gig.
	uploaded := aScore(t)
	helpers.MustPutEntry(t, owner.ApiClient, setId, paperId,
		&api.WriteSetEntry{ScoreID: api.NewNilUUID(uploaded), Description: "the medley", Position: 1})

	after := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, []uuid.UUID{first, uploaded, last}, helpers.ScoreIdsOf(after))
}

// ---------------------------------------------------------------------------
// WHAT A VIEW REFUSES
// ---------------------------------------------------------------------------

// A size outside the range the player offers is a client that is wrong rather
// than a reading that went too far, so it is refused rather than brought back
// into range.
func TestAViewRefusesASizeAScoreCannotBeDrawnAt(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Out of range", nil))
	entryId := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0].ID

	for name, zoom := range map[string]float64{
		"bigger than the player draws":  4.5,
		"smaller than the player draws": 0.1,
	} {
		t.Run(name, func(t *testing.T) {
			res, err := owner.PutSetEntryView(t.Context(), helpers.AViewAtZoom(0, zoom),
				api.PutSetEntryViewParams{SetId: setId, EntryId: entryId})

			require.NoError(t, err)
			assert.IsTypef(t, &api.PutSetEntryViewBadRequest{}, res, "got %#v", res)
		})
	}
}

func TestAViewOfAnEntryThatIsNotInTheSetIsNotFound(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId, otherSetId := uuid.New(), uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Ours", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)
	helpers.MustPutSet(t, owner.ApiClient, otherSetId, helpers.WriteSetOf("Another", nil))
	helpers.MustFillSet(t, owner.ApiClient, otherSetId, scoreId)

	entryOfTheOtherSet := helpers.MustGetSet(t, owner.ApiClient, otherSetId).Entries[0].ID

	for name, entryId := range map[string]uuid.UUID{
		"an entry that was never written": uuid.New(),
		"an entry of another set":         entryOfTheOtherSet,
	} {
		t.Run(name, func(t *testing.T) {
			res, err := owner.PutSetEntryView(t.Context(), helpers.AView(2),
				api.PutSetEntryViewParams{SetId: setId, EntryId: entryId})

			require.NoError(t, err)
			assert.IsTypef(t, &api.PutSetEntryViewNotFound{}, res, "got %#v", res)
		})
	}
}

// Saying "not yours" about a set would say that it exists.
func TestAViewCannotBeWrittenOnASetTheCallerCannotRead(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Private", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)
	entryId := helpers.MustGetSet(t, owner.ApiClient, setId).Entries[0].ID

	res, err := stranger.PutSetEntryView(t.Context(), helpers.AView(2),
		api.PutSetEntryViewParams{SetId: setId, EntryId: entryId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetEntryViewNotFound{}, res, "got %#v", res)
}

func TestAViewRefusesATranspositionThePlayerCannotShow(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Range", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)
	entryId := helpers.MustGetSet(t, owner.ApiClient, setId).Entries[0].ID

	res, err := owner.PutSetEntryView(t.Context(), helpers.AView(13),
		api.PutSetEntryViewParams{SetId: setId, EntryId: entryId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetEntryViewBadRequest{}, res, "got %#v", res)
}

// An entry id is scoped to the set it is in. Taking one over would point this
// set's entry at what another set's players said about theirs.
func TestASetRefusesAnEntryThatBelongsToAnotherSet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	otherSetId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, otherSetId, helpers.WriteSetOf("Another", nil))
	helpers.MustFillSet(t, owner.ApiClient, otherSetId, scoreId)
	entryOfTheOtherSet := helpers.MustGetSet(t, owner.ApiClient, otherSetId).Entries[0]

	ourSetId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, ourSetId, helpers.WriteSetOf("Ours", nil))

	res, err := owner.PutSetEntry(t.Context(), helpers.TheSameEntry(entryOfTheOtherSet),
		api.PutSetEntryParams{SetId: ourSetId, EntryId: entryOfTheOtherSet.ID})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutSetEntryBadRequest)
	require.Truef(t, ok, "got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeInvalidSetEntry, badRequest.ErrorCode)
	assert.Empty(t, helpers.MustGetSet(t, owner.ApiClient, ourSetId).Entries)
	assert.Len(t, helpers.MustGetSet(t, owner.ApiClient, otherSetId).Entries, 1,
		"the other set lost the entry it was holding")
}

// Only the owner arranges a set: what the band plays is the set, and the set is
// theirs. How anybody reads it is not, which is the view.
func TestOnlyTheOwnerWritesTheEntriesOfASet(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Theirs", []string{bandMember.Email}))
	entry := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0]

	written, err := bandMember.PutSetEntry(t.Context(), helpers.AnEntry(scoreId, 0),
		api.PutSetEntryParams{SetId: setId, EntryId: uuid.New()})
	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetEntryForbidden{}, written, "got %#v", written)

	deleted, err := bandMember.DeleteSetEntry(t.Context(),
		api.DeleteSetEntryParams{SetId: setId, EntryId: entry.ID})
	require.NoError(t, err)
	assert.IsTypef(t, &api.DeleteSetEntryForbidden{}, deleted, "got %#v", deleted)

	assert.Len(t, helpers.MustGetSet(t, owner.ApiClient, setId).Entries, 1,
		"a set was arranged by someone who does not own it")
}

// Saying "not yours" about a set would say that it exists.
func TestAnEntryOfASetTheCallerCannotSeeIsNotFound(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Private", nil))
	entry := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0]

	written, err := stranger.PutSetEntry(t.Context(), helpers.AnEntry(scoreId, 0),
		api.PutSetEntryParams{SetId: setId, EntryId: uuid.New()})
	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetEntryNotFound{}, written, "got %#v", written)

	deleted, err := stranger.DeleteSetEntry(t.Context(),
		api.DeleteSetEntryParams{SetId: setId, EntryId: entry.ID})
	require.NoError(t, err)
	assert.IsTypef(t, &api.DeleteSetEntryNotFound{}, deleted, "got %#v", deleted)
}

func TestTakingOutAnEntryThatIsNotInTheSetIsNotFound(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Empty", nil))

	res, err := owner.DeleteSetEntry(t.Context(),
		api.DeleteSetEntryParams{SetId: setId, EntryId: uuid.New()})

	require.NoError(t, err)
	assert.IsTypef(t, &api.DeleteSetEntryNotFound{}, res, "got %#v", res)
}

func TestAnEntryOfASetThatIsNotThereIsNotFound(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	res, err := owner.PutSetEntry(t.Context(), helpers.AnEntry(aScore(t), 0),
		api.PutSetEntryParams{SetId: uuid.New(), EntryId: uuid.New()})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetEntryNotFound{}, res, "got %#v", res)
}

// Correcting a title is correcting a title. Before entries were their own
// resource this was a real hazard: a client that had not looked at the running
// order in a while could undo it by saying nothing about it.
func TestWritingASetLeavesWhatIsPlayedInItAlone(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	first, second := aScore(t), aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Friday", nil))
	helpers.MustFillSet(t, owner.ApiClient, setId, first, second)

	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Friday, corrected", nil))

	saved := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, "Friday, corrected", saved.Title)
	assert.Equal(t, []uuid.UUID{first, second}, helpers.ScoreIdsOf(saved),
		"correcting the title emptied the set")
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

// positionsOf is where the entries of a set say they are played, which should
// always be nought upwards with no gaps in it.
func positionsOf(set *api.Set) []int {
	positions := make([]int, 0, len(set.Entries))
	for _, entry := range set.Entries {
		positions = append(positions, entry.Position)
	}
	return positions
}

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

//go:build integration

package integration_test

import (
	"net/http"
	"testing"
	"time"

	"score/internal/api"
	"score/internal/auth"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// aTitledScore uploads a score with a title of the test's choosing, for the
// tests about the order a collection comes back in. Uploading takes the editor
// role, which a player deliberately does not have.
func aTitledScore(t *testing.T, title string) uuid.UUID {
	t.Helper()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")
	client.Security.Token = idp.IssueToken(t, auth.RoleScoreViewer, auth.RoleScoreEditor)

	scoreId := uuid.New()
	helpers.MustPutScore(t, client, scoreId, helpers.MusicXmlTitled(title))
	return scoreId
}

// ---------------------------------------------------------------------------
// A COLLECTION IS A GROUP OF PIECES
// ---------------------------------------------------------------------------

func TestCreatingACollectionStoresWhatWasGiven(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	collectionId := uuid.New()
	write := helpers.WriteCollectionOf("The Real Book, vol. 1", nil)
	write.Description = "what we can be asked for"
	helpers.MustPutCollection(t, owner.ApiClient, collectionId, write)

	saved := helpers.MustGetCollection(t, owner.ApiClient, collectionId)

	assert.Equal(t, collectionId, saved.ID)
	assert.Equal(t, "The Real Book, vol. 1", saved.Title)
	assert.Equal(t, "what we can be asked for", saved.Description)
	assert.True(t, saved.IsOwner, "the user who created a collection owns it")
	assert.True(t, saved.DeletedAt.Null, "a collection that was just created is not deleted")
	assert.NotNil(t, saved.Entries, "entries should be an empty list, never null")
	assert.NotNil(t, saved.SharedWith, "shared_with should be an empty list, never null")
}

// A collection is created empty and filled afterwards, so correcting a title
// cannot empty the book.
func TestWritingACollectionLeavesWhatIsInItAlone(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Before", nil))
	helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)

	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("After", nil))

	saved := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	assert.Equal(t, "After", saved.Title)
	require.Len(t, saved.Entries, 1, "correcting the title emptied the collection")
	assert.Equal(t, scoreId, saved.Entries[0].ScoreID.Value)
}

// A collection has no order of its own, so it comes back in the one order that
// is any use to somebody looking through it.
func TestACollectionComesBackByTitle(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	titles := map[uuid.UUID]string{}
	for _, title := range []string{"Ruby, My Dear", "All The Things You Are", "Misty"} {
		titles[aTitledScore(t, title)] = title
	}

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))
	for scoreId := range titles {
		helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
			helpers.ACollectionEntry(scoreId))
	}
	// A piece nobody has scanned is filed under what is written next to it,
	// which is the only name it has.
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.AnUnscannedEntry("Blue Bossa"))

	saved := helpers.MustGetCollection(t, owner.ApiClient, collectionId)

	assert.Equal(t,
		[]string{"All The Things You Are", "Blue Bossa", "Misty", "Ruby, My Dear"},
		helpers.TitlesOf(saved, titles))
}

// ---------------------------------------------------------------------------
// A COLLECTION HOLDS A PIECE ONCE
// ---------------------------------------------------------------------------

func TestAScoreCannotBeInACollectionTwice(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))
	alreadyIn := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	res, err := owner.PutCollectionEntry(t.Context(), helpers.ACollectionEntry(scoreId),
		api.PutCollectionEntryParams{CollectionId: collectionId, EntryId: uuid.New()})

	require.NoError(t, err)
	conflict, ok := res.(*api.PutCollectionEntryConflict)
	require.Truef(t, ok, "a second copy of a piece should be refused, got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeScoreAlreadyInCollection, conflict.ErrorCode)
	assert.Equal(t, `"`+alreadyIn.ID.String()+`"`,
		string(conflict.AdditionalProps["entryId"]),
		"the refusal should name the entry the piece is already in")

	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries, 1,
		"a refused entry should not have been stored")
}

// Writing the entry a score is already in is not putting the piece in twice: it
// is saying what the group does with a piece the collection already holds,
// which is the whole point of an entry.
func TestTheEntryAScoreIsInCanBeWrittenAgain(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))
	entry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	write := helpers.TheSameCollectionEntry(*entry)
	write.Transposition = -2
	write.Description = "the arrangement we do"
	saved := helpers.MustPutCollectionEntry(
		t, owner.ApiClient, collectionId, entry.ID, write)

	assert.Equal(t, -2, saved.Transposition)
	assert.Equal(t, "the arrangement we do", saved.Description)
	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries, 1)
}

// They have no score to be the same score, and they are told apart by what is
// written next to them: two lines of a book nobody has scanned are two pieces.
func TestTwoPiecesWithNoScoreAreTwoPieces(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("The red folder", nil))
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.AnUnscannedEntry("page 12"))
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.AnUnscannedEntry("page 44"))

	saved := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	assert.Len(t, saved.Entries, 2)
}

// The rule is about one collection, not about the score: a piece belongs to as
// many books as it is printed in.
func TestAScoreCanBeInMoreThanOneCollection(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	first, second := uuid.New(), uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, first, helpers.WriteCollectionOf("One", nil))
	helpers.MustPutCollection(t, owner.ApiClient, second, helpers.WriteCollectionOf("Two", nil))
	helpers.MustFillCollection(t, owner.ApiClient, first, scoreId)
	helpers.MustFillCollection(t, owner.ApiClient, second, scoreId)

	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, first).Entries, 1)
	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, second).Entries, 1)
}

func TestAPieceThatIsTakenOutCanBePutBackIn(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))
	entry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	helpers.MustDeleteCollectionEntry(t, owner.ApiClient, collectionId, entry.ID)
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.ACollectionEntry(scoreId))

	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries, 1,
		"the rule is about what is in the collection now")
}

// ---------------------------------------------------------------------------
// WHAT IS REFUSED
// ---------------------------------------------------------------------------

// A collection has nowhere for a piece to come, so an unnamed one could never
// be found, sorted, or told from the next unnamed one — and being told apart by
// what is written next to them is the whole reason these are outside the rule
// that a score is in a collection once.
//
// This is where a collection parts company with a set, where a blank line is a
// place in the gig and where it comes is what it means.
func TestAPieceWithNoScoreHasToBeCalledSomething(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("The red folder", nil))

	res, err := owner.PutCollectionEntry(t.Context(), helpers.AnUnscannedEntry("   "),
		api.PutCollectionEntryParams{CollectionId: collectionId, EntryId: uuid.New()})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutCollectionEntryBadRequest)
	require.Truef(t, ok, "an unnamed piece should be refused, got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeInvalidCollectionEntry, badRequest.ErrorCode)
	assert.Empty(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries)
}

// A piece with a score is called by its score, so there is nothing it has to
// have written next to it.
func TestAPieceWithAScoreNeedsNothingWrittenNextToIt(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))

	saved := helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.ACollectionEntry(scoreId))

	assert.Empty(t, saved.Description)
}

// The name is the only thing a piece with no score has, so it cannot be taken
// away by writing the entry again without it.
func TestAPieceWithNoScoreCannotHaveItsNameTakenAway(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("The red folder", nil))
	entryId := uuid.New()
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, entryId,
		helpers.AnUnscannedEntry("page 12"))

	res, err := owner.PutCollectionEntry(t.Context(), helpers.AnUnscannedEntry(""),
		api.PutCollectionEntryParams{CollectionId: collectionId, EntryId: entryId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutCollectionEntryBadRequest{}, res, "got %#v", res)

	kept := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	require.Len(t, kept.Entries, 1)
	assert.Equal(t, "page 12", kept.Entries[0].Description)
}

func TestAnEntryNamingAScoreThatDoesNotExistIsRefused(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Ghost", nil))

	res, err := owner.PutCollectionEntry(t.Context(), helpers.ACollectionEntry(uuid.New()),
		api.PutCollectionEntryParams{CollectionId: collectionId, EntryId: uuid.New()})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutCollectionEntryBadRequest)
	require.Truef(t, ok, "got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeUnknownScore, badRequest.ErrorCode)
	assert.Empty(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries)
}

// An id that already belongs to another collection's entry is refused rather
// than taken over: it would point this collection's entry at what another
// collection's players said about theirs.
func TestAnEntryOfAnotherCollectionIsNotTakenOver(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	theirs, ours := uuid.New(), uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, theirs, helpers.WriteCollectionOf("Theirs", nil))
	helpers.MustPutCollection(t, owner.ApiClient, ours, helpers.WriteCollectionOf("Ours", nil))
	entry := helpers.MustFillCollection(t, owner.ApiClient, theirs, scoreId)[0]

	res, err := owner.PutCollectionEntry(t.Context(),
		helpers.TheSameCollectionEntry(*entry),
		api.PutCollectionEntryParams{CollectionId: ours, EntryId: entry.ID})

	require.NoError(t, err)
	badRequest, ok := res.(*api.PutCollectionEntryBadRequest)
	require.Truef(t, ok, "got %#v", res)
	assert.Equal(t, api.ProblemDetailsErrorCodeInvalidCollectionEntry, badRequest.ErrorCode)
	assert.Empty(t, helpers.MustGetCollection(t, owner.ApiClient, ours).Entries)
	assert.Len(t, helpers.MustGetCollection(t, owner.ApiClient, theirs).Entries, 1,
		"the other collection lost the entry it was holding")
}

// ---------------------------------------------------------------------------
// WHOSE COLLECTION IT IS
// ---------------------------------------------------------------------------

func TestOnlyTheOwnerCanChangeACollection(t *testing.T) {
	t.Parallel()

	owner, meddler := aPlayer(t), aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Kept", []string{meddler.Email}))

	res, err := meddler.PutCollection(t.Context(),
		helpers.WriteCollectionOf("Meddled with", nil),
		api.PutCollectionParams{CollectionId: collectionId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutCollectionForbidden{}, res, "got %#v", res)
	assert.Equal(t, "Kept",
		helpers.MustGetCollection(t, owner.ApiClient, collectionId).Title,
		"a collection was changed by someone who does not own it")
}

func TestOnlyTheOwnerCanPutAPieceIntoACollection(t *testing.T) {
	t.Parallel()

	owner, reader := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Theirs", []string{reader.Email}))

	res, err := reader.PutCollectionEntry(t.Context(), helpers.ACollectionEntry(scoreId),
		api.PutCollectionEntryParams{CollectionId: collectionId, EntryId: uuid.New()})

	require.NoError(t, err)
	assert.IsTypef(t, &api.PutCollectionEntryForbidden{}, res, "got %#v", res)
	assert.Empty(t, helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries)
}

// A collection someone cannot see at all is not there for them: saying "not
// yours" about it would say that it exists.
func TestACollectionSomebodyElseHasIsNotThere(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Private", nil))

	res, err := stranger.GetCollection(t.Context(),
		api.GetCollectionParams{CollectionId: collectionId})

	require.NoError(t, err)
	assert.IsTypef(t, &api.GetCollectionNotFound{}, res, "got %#v", res)
}

// Who else somebody shares with is not the business of the people they share
// with.
func TestSharedWithIsOnlyFilledInForTheOwner(t *testing.T) {
	t.Parallel()

	owner, reader := aPlayer(t), aPlayer(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Shared", []string{reader.Email}))

	asOwner := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	asReader := helpers.MustGetCollection(t, reader.ApiClient, collectionId)

	assert.Equal(t, []string{reader.Email}, asOwner.SharedWith)
	assert.True(t, asOwner.IsOwner)
	assert.Empty(t, asReader.SharedWith)
	assert.False(t, asReader.IsOwner)
}

// ---------------------------------------------------------------------------
// HOW ONE PLAYER READS A PIECE
// ---------------------------------------------------------------------------

// A view says nothing about the collection and changes nothing anybody else
// sees, so it asks no more of a player than reading the collection does.
func TestAnyoneTheCollectionIsSharedWithWritesTheirOwnView(t *testing.T) {
	t.Parallel()

	owner, reader := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Shared", []string{reader.Email}))
	entry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	helpers.MustPutCollectionEntryView(t, reader.ApiClient, collectionId, entry.ID,
		helpers.AViewAtZoom(5, 1.5, "P2"))

	asReader := helpers.MustGetCollection(t, reader.ApiClient, collectionId)
	assert.Equal(t, 5, asReader.Entries[0].View.Transposition)
	assert.Equal(t, []string{"P2"}, asReader.Entries[0].View.HiddenParts)
	assert.InDelta(t, 1.5, asReader.Entries[0].View.Zoom, 0.0001)

	asOwner := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	assert.Equal(t, 0, asOwner.Entries[0].View.Transposition,
		"one player's reading of a piece turned up in another player's")
	assert.Empty(t, asOwner.Entries[0].View.HiddenParts)
}

// The same score in a set and in a collection is two entries, and what is said
// about one says nothing about the other: the band's arrangement of a tune and
// the book's are two different things to read.
func TestAViewOfACollectionSaysNothingAboutTheSameScoreInASet(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("The gig", nil))
	setEntry := helpers.MustFillSet(t, owner.ApiClient, setId, scoreId)[0]

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("The book", nil))
	collectionEntry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	helpers.MustPutCollectionEntryView(t, owner.ApiClient, collectionId, collectionEntry.ID,
		helpers.AView(7))

	assert.Equal(t, 7,
		helpers.MustGetCollection(t, owner.ApiClient, collectionId).Entries[0].View.Transposition)
	assert.Equal(t, 0,
		helpers.MustGetSet(t, owner.ApiClient, setId).Entries[0].View.Transposition,
		"reading a piece out of a book changed how the same piece is read in the gig")
	assert.Equal(t, setEntry.ID, helpers.MustGetSet(t, owner.ApiClient, setId).Entries[0].ID)
}

// What a player said about how they look at a piece was about a piece that is
// no longer in the collection.
func TestTakingAPieceOutTakesTheViewsOfItAlong(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", nil))
	entry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]
	helpers.MustPutCollectionEntryView(t, owner.ApiClient, collectionId, entry.ID,
		helpers.AView(5))

	helpers.MustDeleteCollectionEntry(t, owner.ApiClient, collectionId, entry.ID)
	putBack := helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.ACollectionEntry(scoreId))

	assert.Equal(t, 0, putBack.View.Transposition,
		"a piece that was put back carried a reading of the one that was taken out")
}

// ---------------------------------------------------------------------------
// SYNCING
// ---------------------------------------------------------------------------

// A client that is holding a copy has to learn that a collection is gone rather
// than syncing it back in as something new.
func TestADeletedCollectionKeepsTurningUpInTheWindow(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	before := time.Now().Add(-time.Minute)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Gone", nil))

	res, err := owner.DeleteCollection(t.Context(),
		api.DeleteCollectionParams{CollectionId: collectionId})
	require.NoError(t, err)
	require.IsTypef(t, &api.DeleteCollectionNoContent{}, res, "got %#v", res)

	listed := helpers.MustListCollections(t, owner.ApiClient, api.ListCollectionsParams{
		ChangesSince: before,
		ChangesUntil: time.Now().Add(time.Minute),
	})

	found, ok := helpers.FindCollection(listed, collectionId)
	require.True(t, ok, "a deleted collection should still turn up in the window")
	assert.False(t, found.DeletedAt.Null, "and should say when it was deleted")

	byId, err := owner.GetCollection(t.Context(),
		api.GetCollectionParams{CollectionId: collectionId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetCollectionNotFound{}, byId,
		"a deleted collection should not be readable by id")
}

// A sync asks for everything that changed for the caller, and a view they wrote
// on another device is exactly that — while somebody else writing theirs is
// not.
func TestAViewPutsTheCollectionInTheWritersWindowOnly(t *testing.T) {
	t.Parallel()

	owner, reader := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Shared", []string{reader.Email}))
	entry := helpers.MustFillCollection(t, owner.ApiClient, collectionId, scoreId)[0]

	// A moment after the collection was written and before the view is, and a
	// whole second at that: a window is asked for as an RFC 3339 moment, which
	// carries no fraction of a second, so a start inside the second the
	// collection was written in arrives as a start before it.
	since := time.Now().Add(time.Second).Truncate(time.Second)
	time.Sleep(time.Until(since) + 10*time.Millisecond)

	helpers.MustPutCollectionEntryView(t, reader.ApiClient, collectionId, entry.ID,
		helpers.AView(5))

	window := api.ListCollectionsParams{
		ChangesSince: since,
		ChangesUntil: time.Now().Add(time.Minute),
	}

	_, inTheReadersWindow := helpers.FindCollection(
		helpers.MustListCollections(t, reader.ApiClient, window), collectionId)
	_, inTheOwnersWindow := helpers.FindCollection(
		helpers.MustListCollections(t, owner.ApiClient, window), collectionId)

	assert.True(t, inTheReadersWindow, "a view a player wrote should reach their other devices")
	assert.False(t, inTheOwnersWindow, "somebody else's view is not a change for this caller")
}

// ---------------------------------------------------------------------------
// WHAT THE ENDPOINT ANSWERS TO
// ---------------------------------------------------------------------------

func TestCollectionsAreForScoreViewers(t *testing.T) {
	t.Parallel()

	h := harness.NewScope()
	idp := helpers.Ensure(t, h.IdentityProvider, "idp")
	client := helpers.Ensure(t, h.ApiClient, "ApiClient")
	client.Security.Token = idp.IssueToken(t)

	res, err := client.ListCollections(t.Context(), api.ListCollectionsParams{
		ChangesSince: time.Now().Add(-time.Minute),
		ChangesUntil: time.Now(),
	})

	require.NoError(t, err)
	assert.IsTypef(t, &api.ListCollectionsForbidden{}, res,
		"a user without the viewer role should be turned away, got %#v", res)
}

func TestAMalformedCollectionIdIsNotAServerError(t *testing.T) {
	t.Parallel()

	owner := aPlayer(t)
	raw := helpers.Ensure(t, harness.NewScope().RawClient, "RawClient")

	res := raw.Do(t, helpers.Request{
		Method: http.MethodGet,
		Path:   "/collections/not-a-collection-id",
		Token:  tokenOf(t, owner),
	})

	assert.Lessf(t, res.StatusCode, http.StatusInternalServerError,
		"a malformed collection id should not be a server error, got %d: %s",
		res.StatusCode, res.Text())
}

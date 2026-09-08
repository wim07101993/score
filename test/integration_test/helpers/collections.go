package helpers

import (
	"fmt"
	"testing"

	"score/internal/api"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

// MustPutCollection writes a collection the test expects to be accepted.
func MustPutCollection(
	t *testing.T,
	client *ApiClient,
	collectionId uuid.UUID,
	write *api.WriteCollection,
) *api.Collection {
	t.Helper()

	res, err := client.PutCollection(t.Context(), write,
		api.PutCollectionParams{CollectionId: collectionId})
	require.NoErrorf(t, err, "failed to write collection %s", collectionId)

	saved, ok := res.(*api.Collection)
	require.Truef(t, ok, "failed to write collection %s: %#v", collectionId, res)
	return saved
}

// MustGetCollection fetches a collection the test expects to be readable.
func MustGetCollection(t *testing.T, client *ApiClient, collectionId uuid.UUID) *api.Collection {
	t.Helper()

	res, err := client.GetCollection(t.Context(),
		api.GetCollectionParams{CollectionId: collectionId})
	require.NoErrorf(t, err, "failed to fetch collection %s", collectionId)

	found, ok := res.(*api.Collection)
	require.Truef(t, ok, "expected collection %s, got %#v", collectionId, res)
	return found
}

// MustListCollections lists the collections that changed within the given
// window.
func MustListCollections(
	t *testing.T,
	client *ApiClient,
	params api.ListCollectionsParams,
) api.GetCollectionsResponse {
	t.Helper()

	res, err := client.ListCollections(t.Context(), params)
	require.NoError(t, err, "failed to list collections")

	page, ok := res.(*api.GetCollectionsResponse)
	require.Truef(t, ok, "expected a page of collections, got %#v", res)
	return *page
}

// FindCollection picks one collection out of a listing. Every listing is of
// whatever the caller has, which in a suite that runs in parallel is more than
// the collection the test is about, so a test says which one it means rather
// than counting.
func FindCollection(
	collections api.GetCollectionsResponse,
	collectionId uuid.UUID,
) (api.Collection, bool) {
	for _, c := range collections {
		if c.ID == collectionId {
			return c, true
		}
	}
	return api.Collection{}, false
}

// ACollectionEntry is a piece with nothing remarkable about it: a score the
// group plays as written, which nobody has said anything about how they look
// at.
func ACollectionEntry(scoreId uuid.UUID) *api.WriteCollectionEntry {
	return &api.WriteCollectionEntry{ScoreID: api.NewNilUUID(scoreId)}
}

// AnUnscannedEntry is a piece that is in the collection but not in here: a page
// of a book nobody has scanned, called by whatever is written next to it.
func AnUnscannedEntry(description string) *api.WriteCollectionEntry {
	return &api.WriteCollectionEntry{
		ScoreID:     api.NilUUID{Null: true},
		Description: description,
	}
}

// TheSameCollectionEntry is an entry written again as it came back, for a test
// that is changing one thing about it.
func TheSameCollectionEntry(entry api.CollectionEntry) *api.WriteCollectionEntry {
	return &api.WriteCollectionEntry{
		ScoreID:       entry.ScoreID,
		Description:   entry.Description,
		Transposition: entry.Transposition,
	}
}

// MustPutCollectionEntry puts one piece into a collection, which is how a score
// gets into one: a collection is created empty and filled afterwards, a piece
// at a time.
func MustPutCollectionEntry(
	t *testing.T,
	client *ApiClient,
	collectionId uuid.UUID,
	entryId uuid.UUID,
	write *api.WriteCollectionEntry,
) *api.CollectionEntry {
	t.Helper()

	res, err := client.PutCollectionEntry(t.Context(), write, api.PutCollectionEntryParams{
		CollectionId: collectionId,
		EntryId:      entryId,
	})
	require.NoErrorf(t, err, "failed to write entry %s", entryId)

	saved, ok := res.(*api.CollectionEntry)
	require.Truef(t, ok, "failed to write entry %s: %#v", entryId, res)
	return saved
}

// MustDeleteCollectionEntry takes one piece out of a collection.
func MustDeleteCollectionEntry(
	t *testing.T,
	client *ApiClient,
	collectionId uuid.UUID,
	entryId uuid.UUID,
) {
	t.Helper()

	res, err := client.DeleteCollectionEntry(t.Context(), api.DeleteCollectionEntryParams{
		CollectionId: collectionId,
		EntryId:      entryId,
	})
	require.NoErrorf(t, err, "failed to delete entry %s", entryId)
	require.IsTypef(t, &api.DeleteCollectionEntryNoContent{}, res,
		"failed to delete entry %s: %#v", entryId, res)
}

// MustFillCollection puts the given scores into a collection, which is what
// most tests want one to be before they start.
func MustFillCollection(
	t *testing.T,
	client *ApiClient,
	collectionId uuid.UUID,
	scoreIds ...uuid.UUID,
) []*api.CollectionEntry {
	t.Helper()

	entries := make([]*api.CollectionEntry, 0, len(scoreIds))
	for _, scoreId := range scoreIds {
		entries = append(entries,
			MustPutCollectionEntry(t, client, collectionId, uuid.New(), ACollectionEntry(scoreId)))
	}
	return entries
}

// MustPutCollectionEntryView writes how the caller looks at one entry, which
// any player the collection is shared with may do for themselves.
func MustPutCollectionEntryView(
	t *testing.T,
	client *ApiClient,
	collectionId uuid.UUID,
	entryId uuid.UUID,
	view *api.WriteEntryView,
) *api.EntryView {
	t.Helper()

	res, err := client.PutCollectionEntryView(t.Context(), view,
		api.PutCollectionEntryViewParams{CollectionId: collectionId, EntryId: entryId})
	require.NoErrorf(t, err, "failed to write the view of entry %s", entryId)

	saved, ok := res.(*api.EntryView)
	require.Truef(t, ok, "failed to write the view of entry %s: %#v", entryId, res)
	return saved
}

// WriteCollectionOf is a collection as a client states it, with the lists
// filled in. They are required by the API, and a test that does not care about
// them should not have to say so.
//
// It says nothing about what is in it: a collection is created empty, and the
// pieces go in one at a time afterwards. See MustFillCollection.
func WriteCollectionOf(title string, sharedWith []string) *api.WriteCollection {
	if sharedWith == nil {
		sharedWith = []string{}
	}
	return &api.WriteCollection{
		Title:       title,
		Description: "",
		SharedWith:  sharedWith,
	}
}

// TitlesOf is what the entries of a collection are filed under, which is what a
// test about the order they come back in compares: the title of the score, and
// what is written next to a piece that has none.
//
// It takes the titles rather than looking them up, since this package has no
// way to ask what a score is called.
func TitlesOf(collection *api.Collection, titles map[uuid.UUID]string) []string {
	names := make([]string, 0, len(collection.Entries))
	for _, entry := range collection.Entries {
		if entry.ScoreID.Null {
			names = append(names, entry.Description)
			continue
		}
		title, known := titles[entry.ScoreID.Value]
		if !known {
			title = fmt.Sprintf("unknown score %s", entry.ScoreID.Value)
		}
		names = append(names, title)
	}
	return names
}

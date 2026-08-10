package helpers

import (
	"testing"

	"score/internal/api"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

// MustPutSet writes a set the test expects to be accepted.
func MustPutSet(t *testing.T, client *ApiClient, setId uuid.UUID, write *api.WriteSet) *api.Set {
	t.Helper()

	res, err := client.PutSet(t.Context(), write, api.PutSetParams{SetId: setId})
	require.NoErrorf(t, err, "failed to write set %s", setId)

	saved, ok := res.(*api.Set)
	require.Truef(t, ok, "failed to write set %s: %#v", setId, res)
	return saved
}

// MustGetSet fetches a set the test expects to be readable.
func MustGetSet(t *testing.T, client *ApiClient, setId uuid.UUID) *api.Set {
	t.Helper()

	res, err := client.GetSet(t.Context(), api.GetSetParams{SetId: setId})
	require.NoErrorf(t, err, "failed to fetch set %s", setId)

	found, ok := res.(*api.Set)
	require.Truef(t, ok, "expected set %s, got %#v", setId, res)
	return found
}

// MustListSets lists the sets that changed within the given window.
func MustListSets(t *testing.T, client *ApiClient, params api.ListSetsParams) api.GetSetsResponse {
	t.Helper()

	res, err := client.ListSets(t.Context(), params)
	require.NoError(t, err, "failed to list sets")

	page, ok := res.(*api.GetSetsResponse)
	require.Truef(t, ok, "expected a page of sets, got %#v", res)
	return *page
}

// FindSet picks one set out of a listing. Every listing is of whatever the
// caller has, which in a suite that runs in parallel is more than the set the
// test is about, so a test says which one it means rather than counting.
func FindSet(sets api.GetSetsResponse, setId uuid.UUID) (api.Set, bool) {
	for _, s := range sets {
		if s.ID == setId {
			return s, true
		}
	}
	return api.Set{}, false
}

// ScoreIdsOf is the scores of a set in playing order, which is what a test
// about ordering compares.
func ScoreIdsOf(set *api.Set) []uuid.UUID {
	ids := make([]uuid.UUID, 0, len(set.Entries))
	for _, entry := range set.Entries {
		ids = append(ids, entry.ScoreID)
	}
	return ids
}

// AnEntry is a set entry with nothing remarkable about it: a score the band
// plays as written, which nobody has said anything about how they look at.
func AnEntry(scoreId uuid.UUID, position int) *api.WriteSetEntry {
	return &api.WriteSetEntry{
		ScoreID:  scoreId,
		Position: position,
	}
}

// TheSameEntry is an entry written again as it came back, for a test that is
// changing one thing about it.
func TheSameEntry(entry api.SetEntry) *api.WriteSetEntry {
	return &api.WriteSetEntry{
		ScoreID:       entry.ScoreID,
		Description:   entry.Description,
		Transposition: entry.Transposition,
		Position:      entry.Position,
	}
}

// MustPutEntry writes one entry of a set, which is how a score gets into one:
// a set is created empty and filled afterwards, an entry at a time.
func MustPutEntry(
	t *testing.T,
	client *ApiClient,
	setId uuid.UUID,
	entryId uuid.UUID,
	write *api.WriteSetEntry,
) *api.SetEntry {
	t.Helper()

	res, err := client.PutSetEntry(t.Context(), write, api.PutSetEntryParams{
		SetId:   setId,
		EntryId: entryId,
	})
	require.NoErrorf(t, err, "failed to write entry %s", entryId)

	saved, ok := res.(*api.SetEntry)
	require.Truef(t, ok, "failed to write entry %s: %#v", entryId, res)
	return saved
}

// MustDeleteEntry takes one score out of a set.
func MustDeleteEntry(t *testing.T, client *ApiClient, setId uuid.UUID, entryId uuid.UUID) {
	t.Helper()

	res, err := client.DeleteSetEntry(t.Context(), api.DeleteSetEntryParams{
		SetId:   setId,
		EntryId: entryId,
	})
	require.NoErrorf(t, err, "failed to delete entry %s", entryId)
	require.IsTypef(t, &api.DeleteSetEntryNoContent{}, res,
		"failed to delete entry %s: %#v", entryId, res)
}

// MustFillSet puts the given scores into a set in the order they are given,
// which is what most tests want a set to be before they start.
func MustFillSet(
	t *testing.T,
	client *ApiClient,
	setId uuid.UUID,
	scoreIds ...uuid.UUID,
) []*api.SetEntry {
	t.Helper()

	entries := make([]*api.SetEntry, 0, len(scoreIds))
	for position, scoreId := range scoreIds {
		entries = append(entries,
			MustPutEntry(t, client, setId, uuid.New(), AnEntry(scoreId, position)))
	}
	return entries
}

// MustPutEntryView writes how the caller looks at one entry, which any player
// the set is shared with may do for themselves.
func MustPutEntryView(
	t *testing.T,
	client *ApiClient,
	setId uuid.UUID,
	entryId uuid.UUID,
	view *api.WriteEntryView,
) *api.EntryView {
	t.Helper()

	res, err := client.PutSetEntryView(t.Context(), view, api.PutSetEntryViewParams{
		SetId:   setId,
		EntryId: entryId,
	})
	require.NoErrorf(t, err, "failed to write the view of entry %s", entryId)

	saved, ok := res.(*api.EntryView)
	require.Truef(t, ok, "failed to write the view of entry %s: %#v", entryId, res)
	return saved
}

// AView is how a player says they look at an entry, with the lists filled in.
func AView(transposition int, hiddenParts ...string) *api.WriteEntryView {
	if hiddenParts == nil {
		hiddenParts = []string{}
	}
	return &api.WriteEntryView{
		Transposition: transposition,
		HiddenParts:   hiddenParts,
	}
}

// WriteSetOf is a set as a client states it, with the lists filled in. They are
// required by the API, and a test that does not care about them should not have
// to say so.
//
// It says nothing about what is played: a set is created empty, and the scores
// go in one at a time afterwards. See MustFillSet.
func WriteSetOf(title string, sharedWith []string) *api.WriteSet {
	if sharedWith == nil {
		sharedWith = []string{}
	}
	return &api.WriteSet{
		Title:       title,
		Description: "",
		SharedWith:  sharedWith,
	}
}

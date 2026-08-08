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

// AnEntry is a set entry with nothing remarkable about it: a score, played as
// written, with everything on screen.
func AnEntry(scoreId uuid.UUID) api.SetEntry {
	return api.SetEntry{
		ID:          uuid.New(),
		ScoreID:     scoreId,
		HiddenParts: []string{},
	}
}

// WriteSetOf is a set as a client states it, with the lists filled in. They are
// required by the API, and a test that does not care about them should not have
// to say so.
func WriteSetOf(title string, entries []api.SetEntry, sharedWith []string) *api.WriteSet {
	if entries == nil {
		entries = []api.SetEntry{}
	}
	if sharedWith == nil {
		sharedWith = []string{}
	}
	return &api.WriteSet{
		Title:       title,
		Description: "",
		Entries:     entries,
		SharedWith:  sharedWith,
	}
}

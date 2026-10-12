//go:build integration

package integration_test

import (
	"testing"

	"score/internal/api"
	"score/test/integration_test/helpers"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func mustDeleteCollection(t *testing.T, client *helpers.ApiClient, collectionId uuid.UUID) {
	t.Helper()

	res, err := client.DeleteCollection(t.Context(), api.DeleteCollectionParams{CollectionId: collectionId})
	require.NoErrorf(t, err, "failed to delete collection %s", collectionId)
	require.IsTypef(t, &api.DeleteCollectionNoContent{}, res,
		"failed to delete collection %s: %#v", collectionId, res)
}

// ---------------------------------------------------------------------------
// SETS
// ---------------------------------------------------------------------------

// Deleting a set takes everything in it with it, so writing one under the same
// id again starts from nothing rather than from what was deleted.
func TestDeletingASetRemovesWhatWasInIt(t *testing.T) {
	t.Parallel()

	owner, bandMember := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	setId, entryId := uuid.New(), uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday", []string{bandMember.Email}))
	helpers.MustPutEntry(t, owner.ApiClient, setId, entryId, helpers.AnEntry(scoreId, 0))

	mustDeleteSet(t, owner.ApiClient, setId)

	res, err := owner.GetSet(t.Context(), api.GetSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetSetNotFound{}, res, "a deleted set should not be readable, got %#v", res)

	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Friday again", nil))

	revived := helpers.MustGetSet(t, owner.ApiClient, setId)
	assert.Equal(t, "Friday again", revived.Title)
	assert.Empty(t, revived.Entries, "what was played in a deleted set should be gone")
	assert.Empty(t, revived.SharedWith, "who a deleted set was shared with should be gone")

	listed := helpers.MustListSets(t, owner.ApiClient,
		api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})
	_, listedAsGone := helpers.FindDeletedSet(listed, setId)
	assert.False(t, listedAsGone, "a set that was brought back should no longer be listed as gone")
}

// Whoever a set was shared with when it was deleted is told it is gone, and so
// is whoever had been taken off it before and may not have synced since.
func TestADeletedSetIsListedToWhoeverItWasSharedWith(t *testing.T) {
	t.Parallel()

	owner, bandMember, formerMember, stranger := aPlayer(t), aPlayer(t), aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday", []string{bandMember.Email, formerMember.Email}))
	helpers.MustPutSet(t, owner.ApiClient, setId,
		helpers.WriteSetOf("Friday", []string{bandMember.Email}))

	mustDeleteSet(t, owner.ApiClient, setId)

	for name, who := range map[string]player{
		"the owner":            owner,
		"a band member":        bandMember,
		"a former band member": formerMember,
	} {
		listed := helpers.MustListSets(t, who.ApiClient,
			api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})
		gone, found := helpers.FindDeletedSet(listed, setId)
		assert.Truef(t, found, "%s should be told the set is gone", name)
		assert.Falsef(t, gone.DeletedAt.IsZero(), "%s should be told when the set went", name)
		_, listedWhole := helpers.FindSet(listed, setId)
		assert.Falsef(t, listedWhole, "%s should not be listed the set as if it were there", name)
	}

	listed := helpers.MustListSets(t, stranger.ApiClient,
		api.ListSetsParams{ChangesSince: aWhileAgo(), ChangesUntil: soon()})
	_, found := helpers.FindDeletedSet(listed, setId)
	assert.False(t, found, "somebody the set had nothing to do with should not hear of it")
}

func TestADeletedSetCannotBeTakenOverBySomebodyElse(t *testing.T) {
	t.Parallel()

	owner, stranger := aPlayer(t), aPlayer(t)

	setId := uuid.New()
	helpers.MustPutSet(t, owner.ApiClient, setId, helpers.WriteSetOf("Mine", nil))
	mustDeleteSet(t, owner.ApiClient, setId)

	res, err := stranger.PutSet(t.Context(), helpers.WriteSetOf("Theirs", nil),
		api.PutSetParams{SetId: setId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.PutSetForbidden{}, res, "got %#v", res)
}

// ---------------------------------------------------------------------------
// COLLECTIONS
// ---------------------------------------------------------------------------

func TestDeletingACollectionRemovesWhatWasInIt(t *testing.T) {
	t.Parallel()

	owner, reader := aPlayer(t), aPlayer(t)
	scoreId := aScore(t)

	collectionId := uuid.New()
	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards", []string{reader.Email}))
	helpers.MustPutCollectionEntry(t, owner.ApiClient, collectionId, uuid.New(),
		helpers.ACollectionEntry(scoreId))

	mustDeleteCollection(t, owner.ApiClient, collectionId)

	res, err := owner.GetCollection(t.Context(), api.GetCollectionParams{CollectionId: collectionId})
	require.NoError(t, err)
	assert.IsTypef(t, &api.GetCollectionNotFound{}, res,
		"a deleted collection should not be readable, got %#v", res)

	listed := helpers.MustListCollections(t, reader.ApiClient, api.ListCollectionsParams{
		ChangesSince: aWhileAgo(),
		ChangesUntil: soon(),
	})
	_, toldItIsGone := helpers.FindDeletedCollection(listed, collectionId)
	assert.True(t, toldItIsGone, "whoever a deleted collection was shared with should be told it is gone")

	helpers.MustPutCollection(t, owner.ApiClient, collectionId,
		helpers.WriteCollectionOf("Standards again", nil))

	revived := helpers.MustGetCollection(t, owner.ApiClient, collectionId)
	assert.Empty(t, revived.Entries, "what was in a deleted collection should be gone")
	assert.Empty(t, revived.SharedWith, "who a deleted collection was shared with should be gone")
}

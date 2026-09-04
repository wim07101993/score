package server

import (
	"context"
	"errors"

	"score/internal"
	"score/internal/api"
	"score/internal/collection"
	"score/internal/oidc"

	"github.com/google/uuid"
)

func (h *Handler) GetCollection(
	ctx context.Context,
	params api.GetCollectionParams,
) (api.GetCollectionRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrGetCollection.WithParent(err)
	}
	defer dbConn.Release()

	found, err := collection.Get(ctx, dbConn, params.CollectionId.String(), user)
	if err != nil {
		if errors.Is(err, collection.ErrCollectionNotFound) {
			return nil, ErrCollectionNotFound
		}
		return nil, ErrGetCollection.WithParent(err)
	}

	return mapCollectionToApi(found)
}

func (h *Handler) ListCollections(
	ctx context.Context,
	params api.ListCollectionsParams,
) (api.ListCollectionsRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrListCollections.WithParent(err)
	}
	defer dbConn.Release()

	collections, err := collection.List(ctx, dbConn, user, params.ChangesSince, params.ChangesUntil)
	if err != nil {
		return nil, ErrListCollections.WithParent(err)
	}

	page := make(api.GetCollectionsResponse, 0, len(collections))
	for _, stored := range collections {
		apiCollection, err := mapCollectionToApi(stored)
		if err != nil {
			return nil, err
		}
		page = append(page, *apiCollection)
	}
	return &page, nil
}

func (h *Handler) PutCollection(
	ctx context.Context,
	req *api.WriteCollection,
	params api.PutCollectionParams,
) (api.PutCollectionRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveCollection.WithParent(err)
	}
	defer dbConn.Release()

	collectionId := params.CollectionId.String()

	write := collection.WriteCollection{
		Title:       req.Title,
		Description: req.Description,
		SharedWith:  req.SharedWith,
	}
	if err := collection.Save(ctx, dbConn, collectionId, user, write); err != nil {
		return nil, saveCollectionFailed(err)
	}

	saved, err := collection.Get(ctx, dbConn, collectionId, user)
	if err != nil {
		return nil, ErrSaveCollection.WithParent(err)
	}
	return mapCollectionToApi(saved)
}

// PutCollectionEntry puts one piece into a collection, or changes what the
// group does with it.
//
// An entry is its own resource because a collection is not rewritten to change
// one piece in it: a client that added a piece sends that piece. What is in the
// collection is the collection and the collection is the owner's, so only they
// may write it; how anybody reads it is PutCollectionEntryView, which everyone
// writes for themselves.
func (h *Handler) PutCollectionEntry(
	ctx context.Context,
	req *api.WriteCollectionEntry,
	params api.PutCollectionEntryParams,
) (api.PutCollectionEntryRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveCollectionEntry.WithParent(err)
	}
	defer dbConn.Release()

	saved, err := collection.SaveEntry(
		ctx,
		dbConn,
		params.CollectionId.String(),
		params.EntryId.String(),
		user,
		collection.WriteEntry{
			ScoreId:       scoreIdFromApi(req.ScoreID),
			Description:   req.Description,
			Transposition: req.Transposition,
		})
	if err != nil {
		return nil, saveCollectionEntryFailed(err)
	}

	entry, err := mapCollectionEntryToApi(*saved)
	if err != nil {
		return nil, err
	}
	return entry, nil
}

// DeleteCollectionEntry takes one piece out of a collection.
func (h *Handler) DeleteCollectionEntry(
	ctx context.Context,
	params api.DeleteCollectionEntryParams,
) (api.DeleteCollectionEntryRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrDeleteCollectionEntry.WithParent(err)
	}
	defer dbConn.Release()

	err = collection.DeleteEntry(
		ctx, dbConn, params.CollectionId.String(), params.EntryId.String(), user)
	switch {
	case errors.Is(err, collection.ErrCollectionNotFound):
		return nil, ErrCollectionNotFound
	case errors.Is(err, collection.ErrCollectionEntryNotFound):
		return nil, ErrCollectionEntryNotFound
	case errors.Is(err, collection.ErrNotCollectionOwner):
		return nil, ErrNotCollectionOwner
	case err != nil:
		return nil, ErrDeleteCollectionEntry.WithParent(err)
	}

	return &api.DeleteCollectionEntryNoContent{}, nil
}

// PutCollectionEntryView stores how the caller looks at one entry of a
// collection.
//
// It asks no more of a caller than reading the collection does: a view says
// nothing about the collection and changes nothing anybody else sees, so
// everyone it is shared with writes their own. Whose view it is comes from the
// token rather than from the request, so there is no way to write somebody
// else's.
func (h *Handler) PutCollectionEntryView(
	ctx context.Context,
	req *api.WriteEntryView,
	params api.PutCollectionEntryViewParams,
) (api.PutCollectionEntryViewRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveCollectionEntryView.WithParent(err)
	}
	defer dbConn.Release()

	saved, err := collection.SaveEntryView(
		ctx,
		dbConn,
		params.CollectionId.String(),
		params.EntryId.String(),
		user,
		collection.WriteEntryView{
			Transposition: req.Transposition,
			HiddenParts:   req.HiddenParts,
			Zoom:          req.Zoom.Or(collection.DefaultZoom),
		})
	if err != nil {
		if errors.Is(err, collection.ErrCollectionEntryNotFound) {
			return nil, ErrCollectionEntryNotFound
		}
		var invalid *collection.ErrInvalidCollection
		if errors.As(err, &invalid) {
			return nil, ErrInvalidCollection.
				WithAdditionalData("reason", invalid.Reason).
				WithParent(err)
		}
		return nil, ErrSaveCollectionEntryView.WithParent(err)
	}

	view := mapCollectionEntryViewToApi(*saved)
	return &view, nil
}

func (h *Handler) DeleteCollection(
	ctx context.Context,
	params api.DeleteCollectionParams,
) (api.DeleteCollectionRes, error) {
	user, err := collectionCallerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrDeleteCollection.WithParent(err)
	}
	defer dbConn.Release()

	if err := collection.Delete(ctx, dbConn, params.CollectionId.String(), user); err != nil {
		if errors.Is(err, collection.ErrCollectionNotFound) {
			return nil, ErrCollectionNotFound
		}
		return nil, ErrDeleteCollection.WithParent(err)
	}

	return &api.DeleteCollectionNoContent{}, nil
}

func saveCollectionFailed(err error) error {
	var invalid *collection.ErrInvalidCollection
	if errors.As(err, &invalid) {
		return ErrInvalidCollection.
			WithAdditionalData("reason", invalid.Reason).
			WithParent(err)
	}

	if errors.Is(err, collection.ErrNotCollectionOwner) {
		return ErrNotCollectionOwner
	}

	return ErrSaveCollection.WithParent(err)
}

func saveCollectionEntryFailed(err error) error {
	// The piece is already in the collection. The entry it is already in goes
	// along with the refusal: a client that has just been told a piece is in
	// the book wants that page, not a second copy of it.
	var alreadyIn *collection.ErrScoreAlreadyInCollection
	if errors.As(err, &alreadyIn) {
		refusal := ErrScoreAlreadyInCollection.
			WithAdditionalData("scoreId", alreadyIn.ScoreId)
		if alreadyIn.EntryId != "" {
			refusal = refusal.WithAdditionalData("entryId", alreadyIn.EntryId)
		}
		return refusal.WithParent(err)
	}

	var invalid *collection.ErrInvalidCollectionEntry
	if errors.As(err, &invalid) {
		return ErrInvalidCollectionEntry.
			WithAdditionalData("reason", invalid.Reason).
			WithParent(err)
	}

	var unknownScore *collection.ErrUnknownScore
	if errors.As(err, &unknownScore) {
		return ErrUnknownScoreInCollection.
			WithAdditionalData("scoreId", unknownScore.ScoreId).
			WithParent(err)
	}

	switch {
	case errors.Is(err, collection.ErrCollectionNotFound):
		return ErrCollectionNotFound
	case errors.Is(err, collection.ErrNotCollectionOwner):
		return ErrNotCollectionOwner
	}

	return ErrSaveCollectionEntry.WithParent(err)
}

// collectionCallerOf is who is asking, as this package's collections know a
// caller. It is the same person the sets know, asked for in the terms that
// package uses: neither of them has to hear about how somebody proved who they
// are.
func collectionCallerOf(ctx context.Context) (collection.User, error) {
	user, ok := ctx.Value(internal.UserInfoKey).(*oidc.UserInfo)
	if !ok {
		return collection.User{}, ErrNoUserInfo
	}
	return collection.NewUser(user.Subject, user.Email), nil
}

func mapCollectionToApi(stored *collection.Collection) (*api.Collection, error) {
	id, err := uuid.Parse(stored.Id)
	if err != nil {
		return nil, ErrUnknown.WithParent(err)
	}

	entries := make([]api.CollectionEntry, 0, len(stored.Entries))
	for _, entry := range stored.Entries {
		mapped, err := mapCollectionEntryToApi(entry)
		if err != nil {
			return nil, err
		}
		entries = append(entries, *mapped)
	}

	deletedAt := api.NilDateTime{Null: true}
	if stored.DeletedAt != nil {
		deletedAt = api.NewNilDateTime(*stored.DeletedAt)
	}

	return &api.Collection{
		ID:            id,
		Title:         stored.Title,
		Description:   stored.Description,
		Entries:       entries,
		SharedWith:    stored.SharedWith,
		IsOwner:       stored.IsOwner,
		LastChangedAt: stored.LastChangedAt,
		DeletedAt:     deletedAt,
	}, nil
}

func mapCollectionEntryToApi(entry collection.Entry) (*api.CollectionEntry, error) {
	entryId, err := uuid.Parse(entry.Id)
	if err != nil {
		return nil, ErrUnknown.WithParent(err)
	}

	scoreId := api.NilUUID{Null: true}
	if entry.ScoreId != nil {
		parsed, err := uuid.Parse(*entry.ScoreId)
		if err != nil {
			return nil, ErrUnknown.WithParent(err)
		}
		scoreId = api.NewNilUUID(parsed)
	}

	return &api.CollectionEntry{
		ID:            entryId,
		ScoreID:       scoreId,
		Description:   entry.Description,
		Transposition: entry.Transposition,
		View:          mapCollectionEntryViewToApi(entry.View),
	}, nil
}

// mapCollectionEntryViewToApi keeps an absent list an empty one: an entry
// nobody has looked at differently has every part on screen, which is a list of
// no parts rather than no list.
func mapCollectionEntryViewToApi(view collection.EntryView) api.EntryView {
	hidden := view.HiddenParts
	if hidden == nil {
		hidden = []string{}
	}
	zoom := view.Zoom
	if zoom == 0 {
		zoom = collection.DefaultZoom
	}

	return api.EntryView{
		Transposition: view.Transposition,
		HiddenParts:   hidden,
		Zoom:          zoom,
	}
}

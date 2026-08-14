package server

import (
	"context"
	"errors"

	"score/internal"
	"score/internal/api"
	"score/internal/oidc"
	"score/internal/set"

	"github.com/google/uuid"
)

func (h *Handler) GetSet(ctx context.Context, params api.GetSetParams) (api.GetSetRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrGetSet.WithParent(err)
	}
	defer dbConn.Release()

	found, err := set.Get(ctx, dbConn, params.SetId.String(), user)
	if err != nil {
		if errors.Is(err, set.ErrSetNotFound) {
			return nil, ErrSetNotFound
		}
		return nil, ErrGetSet.WithParent(err)
	}

	return mapSetToApi(found)
}

func (h *Handler) ListSets(ctx context.Context, params api.ListSetsParams) (api.ListSetsRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrListSets.WithParent(err)
	}
	defer dbConn.Release()

	sets, err := set.List(ctx, dbConn, user, params.ChangesSince, params.ChangesUntil)
	if err != nil {
		return nil, ErrListSets.WithParent(err)
	}

	page := make(api.GetSetsResponse, 0, len(sets))
	for _, stored := range sets {
		apiSet, err := mapSetToApi(stored)
		if err != nil {
			return nil, err
		}
		page = append(page, *apiSet)
	}
	return &page, nil
}

func (h *Handler) PutSet(ctx context.Context, req *api.WriteSet, params api.PutSetParams) (api.PutSetRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveSet.WithParent(err)
	}
	defer dbConn.Release()

	setId := params.SetId.String()

	if err := set.Save(ctx, dbConn, setId, user, mapWriteSetFromApi(req)); err != nil {
		return nil, saveSetFailed(err)
	}

	saved, err := set.Get(ctx, dbConn, setId, user)
	if err != nil {
		return nil, ErrSaveSet.WithParent(err)
	}
	return mapSetToApi(saved)
}

// PutSetEntry puts one score into a set, or changes how it is played.
//
// An entry is its own resource because a set is not rewritten to change one
// song in it: a client that added a song sends that song. What the band plays
// is the set and the set is the owner's, so only they may write it; how anybody
// reads it is PutSetEntryView, which everyone writes for themselves.
func (h *Handler) PutSetEntry(
	ctx context.Context,
	req *api.WriteSetEntry,
	params api.PutSetEntryParams,
) (api.PutSetEntryRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveSetEntry.WithParent(err)
	}
	defer dbConn.Release()

	saved, err := set.SaveEntry(
		ctx,
		dbConn,
		params.SetId.String(),
		params.EntryId.String(),
		user,
		set.WriteEntry{
			ScoreId:       scoreIdFromApi(req.ScoreID),
			Description:   req.Description,
			Transposition: req.Transposition,
			Position:      req.Position,
		})
	if err != nil {
		return nil, saveSetEntryFailed(err)
	}

	entry, err := mapEntryToApi(*saved)
	if err != nil {
		return nil, err
	}
	return entry, nil
}

// DeleteSetEntry takes one score out of a set.
func (h *Handler) DeleteSetEntry(
	ctx context.Context,
	params api.DeleteSetEntryParams,
) (api.DeleteSetEntryRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrDeleteSetEntry.WithParent(err)
	}
	defer dbConn.Release()

	err = set.DeleteEntry(ctx, dbConn, params.SetId.String(), params.EntryId.String(), user)
	switch {
	case errors.Is(err, set.ErrSetNotFound):
		return nil, ErrSetNotFound
	case errors.Is(err, set.ErrSetEntryNotFound):
		return nil, ErrSetEntryNotFound
	case errors.Is(err, set.ErrNotSetOwner):
		return nil, ErrNotSetOwner
	case err != nil:
		return nil, ErrDeleteSetEntry.WithParent(err)
	}

	return &api.DeleteSetEntryNoContent{}, nil
}

// PutSetEntryView stores how the caller looks at one entry of a set.
//
// It asks no more of a caller than reading the set does: a view says nothing
// about the set and changes nothing anybody else sees, so everyone the set is
// shared with writes their own. Whose view it is comes from the token rather
// than from the request, so there is no way to write somebody else's.
func (h *Handler) PutSetEntryView(
	ctx context.Context,
	req *api.WriteEntryView,
	params api.PutSetEntryViewParams,
) (api.PutSetEntryViewRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrSaveSetEntryView.WithParent(err)
	}
	defer dbConn.Release()

	saved, err := set.SaveEntryView(
		ctx,
		dbConn,
		params.SetId.String(),
		params.EntryId.String(),
		user,
		set.WriteEntryView{
			Transposition: req.Transposition,
			HiddenParts:   req.HiddenParts,
			Zoom:          req.Zoom.Or(set.DefaultZoom),
		})
	if err != nil {
		if errors.Is(err, set.ErrSetEntryNotFound) {
			return nil, ErrSetEntryNotFound
		}
		var invalid *set.ErrInvalidSet
		if errors.As(err, &invalid) {
			return nil, ErrInvalidSet.
				WithAdditionalData("reason", invalid.Reason).
				WithParent(err)
		}
		return nil, ErrSaveSetEntryView.WithParent(err)
	}

	view := mapEntryViewToApi(*saved)
	return &view, nil
}

func (h *Handler) DeleteSet(ctx context.Context, params api.DeleteSetParams) (api.DeleteSetRes, error) {
	user, err := callerOf(ctx)
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, ErrDeleteSet.WithParent(err)
	}
	defer dbConn.Release()

	if err := set.Delete(ctx, dbConn, params.SetId.String(), user); err != nil {
		if errors.Is(err, set.ErrSetNotFound) {
			return nil, ErrSetNotFound
		}
		return nil, ErrDeleteSet.WithParent(err)
	}

	return &api.DeleteSetNoContent{}, nil
}

func saveSetFailed(err error) error {
	var invalid *set.ErrInvalidSet
	if errors.As(err, &invalid) {
		return ErrInvalidSet.
			WithAdditionalData("reason", invalid.Reason).
			WithParent(err)
	}

	if errors.Is(err, set.ErrNotSetOwner) {
		return ErrNotSetOwner
	}

	return ErrSaveSet.WithParent(err)
}

func saveSetEntryFailed(err error) error {
	var invalid *set.ErrInvalidSetEntry
	if errors.As(err, &invalid) {
		return ErrInvalidSetEntry.
			WithAdditionalData("reason", invalid.Reason).
			WithParent(err)
	}

	var unknownScore *set.ErrUnknownScore
	if errors.As(err, &unknownScore) {
		return ErrUnknownScore.
			WithAdditionalData("scoreId", unknownScore.ScoreId).
			WithParent(err)
	}

	switch {
	case errors.Is(err, set.ErrSetNotFound):
		return ErrSetNotFound
	case errors.Is(err, set.ErrNotSetOwner):
		return ErrNotSetOwner
	}

	return ErrSaveSetEntry.WithParent(err)
}

func callerOf(ctx context.Context) (set.User, error) {
	user, ok := ctx.Value(internal.UserInfoKey).(*oidc.UserInfo)
	if !ok {
		return set.User{}, ErrNoUserInfo
	}
	return set.NewUser(user.Subject, user.Email), nil
}

func mapSetToApi(stored *set.Set) (*api.Set, error) {
	id, err := uuid.Parse(stored.Id)
	if err != nil {
		return nil, ErrUnknown.WithParent(err)
	}

	entries := make([]api.SetEntry, 0, len(stored.Entries))
	for _, entry := range stored.Entries {
		mapped, err := mapEntryToApi(entry)
		if err != nil {
			return nil, err
		}
		entries = append(entries, *mapped)
	}

	deletedAt := api.NilDateTime{Null: true}
	if stored.DeletedAt != nil {
		deletedAt = api.NewNilDateTime(*stored.DeletedAt)
	}

	return &api.Set{
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

func mapEntryToApi(entry set.Entry) (*api.SetEntry, error) {
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

	return &api.SetEntry{
		ID:            entryId,
		ScoreID:       scoreId,
		Description:   entry.Description,
		Position:      entry.Position,
		Transposition: entry.Transposition,
		View:          mapEntryViewToApi(entry.View),
	}, nil
}

// scoreIdFromApi is the score an entry names, and nothing at all for a song
// that has none.
func scoreIdFromApi(scoreId api.NilUUID) *string {
	if scoreId.Null {
		return nil
	}
	asString := scoreId.Value.String()
	return &asString
}

// mapEntryViewToApi keeps an absent list an empty one: an entry nobody has
// looked at differently has every part on screen, which is a list of no parts
// rather than no list.
func mapEntryViewToApi(view set.EntryView) api.EntryView {
	hidden := view.HiddenParts
	if hidden == nil {
		hidden = []string{}
	}
	zoom := view.Zoom
	if zoom == 0 {
		zoom = set.DefaultZoom
	}

	return api.EntryView{
		Transposition: view.Transposition,
		HiddenParts:   hidden,
		Zoom:          zoom,
	}
}

func mapWriteSetFromApi(req *api.WriteSet) set.WriteSet {
	return set.WriteSet{
		Title:       req.Title,
		Description: req.Description,
		SharedWith:  req.SharedWith,
	}
}

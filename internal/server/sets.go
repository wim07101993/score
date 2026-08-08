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

	// Read back rather than echo: what a set reads as is not only what was
	// sent. Who owns it, when it changed and which shares survived normalizing
	// are decided while saving, and the client should see those.
	saved, err := set.Get(ctx, dbConn, setId, user)
	if err != nil {
		return nil, ErrSaveSet.WithParent(err)
	}
	return mapSetToApi(saved)
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

// saveSetFailed turns the ways a set can be refused into the answers they
// deserve: what the caller sent, what is not theirs, and what went wrong here.
func saveSetFailed(err error) error {
	var invalid *set.ErrInvalidSet
	if errors.As(err, &invalid) {
		return ErrInvalidSet.
			WithAdditionalData("reason", invalid.Reason).
			WithParent(err)
	}

	var unknownScore *set.ErrUnknownScore
	if errors.As(err, &unknownScore) {
		return ErrUnknownScore.
			WithAdditionalData("scoreId", unknownScore.ScoreId).
			WithParent(err)
	}

	if errors.Is(err, set.ErrNotSetOwner) {
		return ErrNotSetOwner
	}

	return ErrSaveSet.WithParent(err)
}

// callerOf is who the security handler said is asking, as the set package wants
// to hear it.
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
		entryId, err := uuid.Parse(entry.Id)
		if err != nil {
			return nil, ErrUnknown.WithParent(err)
		}
		scoreId, err := uuid.Parse(entry.ScoreId)
		if err != nil {
			return nil, ErrUnknown.WithParent(err)
		}

		entries = append(entries, api.SetEntry{
			ID:            entryId,
			ScoreID:       scoreId,
			Description:   entry.Description,
			Transposition: entry.Transposition,
			HiddenParts:   entry.HiddenParts,
		})
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

func mapWriteSetFromApi(req *api.WriteSet) set.WriteSet {
	entries := make([]set.WriteEntry, 0, len(req.Entries))
	for _, entry := range req.Entries {
		entries = append(entries, set.WriteEntry{
			Id:            entry.ID.String(),
			ScoreId:       entry.ScoreID.String(),
			Description:   entry.Description,
			Transposition: entry.Transposition,
			HiddenParts:   entry.HiddenParts,
		})
	}

	return set.WriteSet{
		Title:       req.Title,
		Description: req.Description,
		Entries:     entries,
		SharedWith:  req.SharedWith,
	}
}

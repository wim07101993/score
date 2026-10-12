package server

import (
	"time"

	"score/internal/api"

	"github.com/google/uuid"
)

func mapDeletedToApi(id string, deletedAt time.Time) (api.DeletedResource, error) {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return api.DeletedResource{}, ErrUnknown.WithParent(err)
	}
	return api.DeletedResource{ID: parsed, DeletedAt: deletedAt}, nil
}

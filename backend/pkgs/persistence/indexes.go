package persistence

import (
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"time"
)

type MeiliIndexes struct {
	logger *slog.Logger
	meili  *meilisearch.Client
}

func NewMeiliIndexes(logger *slog.Logger, meili *meilisearch.Client) *MeiliIndexes {
	return &MeiliIndexes{
		logger: logger,
		meili:  meili,
	}
}

func (idx *MeiliIndexes) waitForTask(taskUID int64, timeout time.Duration) (*meilisearch.Task, error) {
	timedOut := time.Now().UTC().Add(timeout)
	task, err := idx.meili.GetTask(taskUID)
	if err != nil || task == nil {
		return nil, err
	}
	for task.Status != meilisearch.TaskStatusFailed && task.Status != meilisearch.TaskStatusSucceeded {
		if timedOut.Before(time.Now().UTC()) {
			return nil, TaskTimeoutErr
		}

		time.Sleep(time.Duration(1) * time.Second)
		task, err = idx.meili.GetTask(taskUID)
		if err != nil || task == nil {
			return nil, err
		}
	}
	return task, nil
}

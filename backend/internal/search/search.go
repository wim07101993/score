package search

import (
	"errors"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"score/backend/pkgs/models"
	"time"
)

const taskTimeoutErr = "timeout while waiting for task"

type Searcher interface {
	IndexScore(score *models.Score, id string) error
	EnsureIndexesCreated() error
}

type searcher struct {
	Logger *slog.Logger
	Meili  meilisearch.Client
}

func NewSearcher(logger *slog.Logger, meili meilisearch.Client) Searcher {
	return &searcher{
		Logger: logger,
		Meili:  meili,
	}
}

func (s *searcher) waitForTask(taskUID int64, timeout time.Duration) (*meilisearch.Task, error) {
	timedOut := time.Now().UTC().Add(timeout)
	task, err := s.Meili.GetTask(taskUID)
	for task.Status != meilisearch.TaskStatusFailed && task.Status != meilisearch.TaskStatusSucceeded {
		if err != nil {
			return nil, err
		}
		if timedOut.Before(time.Now().UTC()) {
			return nil, errors.New(taskTimeoutErr)
		}

		time.Sleep(time.Duration(1) * time.Second)
		task, err = s.Meili.GetTask(taskUID)
	}
	return task, nil
}

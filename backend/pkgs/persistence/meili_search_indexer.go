package persistence

import (
	"errors"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"time"
)

const ScoresIndex = "scores"

var TaskTimeoutErr = errors.New("timeout while waiting for task")

type Indexer interface {
	Index(score *Score, id string) error
	Remove(id string) error
}

type searcher struct {
	Logger *slog.Logger
	Meili  *meilisearch.Client
}

func NewIndexer(logger *slog.Logger, meili *meilisearch.Client) Indexer {
	return &searcher{
		Logger: logger,
		Meili:  meili,
	}
}

func (s *searcher) Index(score *Score, id string) error {
	s.Logger.Info("indexing document",
		slog.String("title", score.Title),
		slog.String("id", id))

	doc := score.ToDocument(id)
	resp, err := s.Meili.Index(ScoresIndex).AddDocuments(doc)
	if err != nil {
		return err
	}

	_, err = s.waitForTask(resp.TaskUID, time.Duration(30)*time.Second)
	if err != nil {
		return err
	}
	return nil
}

func (s *searcher) Remove(id string) error {
	s.Logger.Info("removing document", slog.String("id", id))
	_, err := s.Meili.Index(ScoresIndex).DeleteDocument(id)
	return err
}

func (s *searcher) waitForTask(taskUID int64, timeout time.Duration) (*meilisearch.Task, error) {
	timedOut := time.Now().UTC().Add(timeout)
	task, err := s.Meili.GetTask(taskUID)
	if err != nil || task == nil {
		return nil, err
	}
	for task.Status != meilisearch.TaskStatusFailed && task.Status != meilisearch.TaskStatusSucceeded {
		if timedOut.Before(time.Now().UTC()) {
			return nil, TaskTimeoutErr
		}

		time.Sleep(time.Duration(1) * time.Second)
		task, err = s.Meili.GetTask(taskUID)
		if err != nil || task == nil {
			return nil, err
		}
	}
	return task, nil
}

package search

import (
	"errors"
	"fmt"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"time"
)

const scoresIndex = "scores"

const (
	indexCreationFailedBecauseOfTimeout = "failed to create index because of a timeout"
)

func (s *searcher) EnsureIndexesCreated() error {
	return s.EnsureIndexCreated(scoresIndex)
}

func (s *searcher) EnsureIndexCreated(indexName string) error {
	s.Logger.Info("creating index", slog.String("indexName", indexName))

	resp, err := s.Meili.CreateIndex(&meilisearch.IndexConfig{
		Uid:        indexName,
		PrimaryKey: "id",
	})
	if err != nil {
		return err
	}

	task, err := s.waitForTask(resp.TaskUID, time.Duration(1)*time.Second)
	if err != nil {
		if err.Error() == taskTimeoutErr {
			return errors.New(indexCreationFailedBecauseOfTimeout)
		}
		return err
	}

	if task.Status == meilisearch.TaskStatusFailed {
		if task.Error.Code == "index_already_exists" {
			return nil
		}
		return fmt.Errorf("failed to create index %s. Reason: %s", indexName, task.Error.Message)
	}

	s.Logger.Debug("created index", slog.String("indexName", indexName))
	return nil
}

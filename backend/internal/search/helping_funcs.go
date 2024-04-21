package search

import (
	"errors"
	"github.com/meilisearch/meilisearch-go"
	"time"
)

var TaskTimeoutErr = errors.New("timeout while waiting for task")

func (s *searcher) waitForTask(taskUID int64, timeout time.Duration) (*meilisearch.Task, error) {
	timedOut := time.Now().UTC().Add(timeout)
	task, err := s.Meili.GetTask(taskUID)
	for task.Status != meilisearch.TaskStatusFailed && task.Status != meilisearch.TaskStatusSucceeded {
		if err != nil {
			return nil, err
		}
		if timedOut.Before(time.Now().UTC()) {
			return nil, TaskTimeoutErr
		}

		time.Sleep(time.Duration(1) * time.Second)
		task, err = s.Meili.GetTask(taskUID)
	}
	return task, nil
}

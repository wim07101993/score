package search

import (
	"errors"
	"log/slog"
	"score/backend/pkgs/models"
	"time"
)

func (s *searcher) IndexScore(score *models.Score, id string) error {
	s.Logger.Info("indexing document", slog.String("title", score.Title))

	doc := ScoreToDocument(score, id)
	resp, err := s.Meili.Index(scoresIndex).AddDocuments(doc)
	if err != nil {
		return err
	}

	_, err = s.waitForTask(resp.TaskUID, time.Duration(30)*time.Second)
	if err != nil {
		if err.Error() == taskTimeoutErr {
			return errors.New(indexCreationFailedBecauseOfTimeout)
		}
		return err
	}
	return nil
}

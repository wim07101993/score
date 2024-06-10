package persistence

import (
	"errors"
	"log/slog"
	"time"
)

const ScoresIndexName = "scores"

var TaskTimeoutErr = errors.New("timeout while waiting for task")

type ScoresIndex interface {
	AddScore(score *Score, id string) error
	RemoveScore(id string) error
}

type Score struct {
	Title       string
	Composers   []string
	Lyricists   []string
	Instruments []string
}

func (idx *MeiliIndexes) AddScore(score *Score, id string) error {
	idx.logger.Info("indexing score document",
		slog.String("title", score.Title),
		slog.String("id", id))

	doc := scoreToDocument(score, id)
	resp, err := idx.meili.Index(ScoresIndexName).AddDocuments(doc)
	if err != nil {
		return err
	}

	_, err = idx.waitForTask(resp.TaskUID, time.Duration(30)*time.Second)
	if err != nil {
		return err
	}
	return nil
}

func (idx *MeiliIndexes) RemoveScore(id string) error {
	idx.logger.Info("removing score document", slog.String("id", id))
	_, err := idx.meili.Index(ScoresIndexName).DeleteDocument(id)
	return err
}

func scoreToDocument(s *Score, id string) map[string]interface{} {
	return map[string]interface{}{
		"id":          id,
		"title":       s.Title,
		"composers":   s.Composers,
		"lyricists":   s.Lyricists,
		"instruments": s.Instruments,
	}
}

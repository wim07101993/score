package search

import (
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"score/backend/pkgs/models"
	"time"
)

const scoresIndex = "scores"

type Indexer interface {
	Index(score *models.Score, id string) error
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

func (s *searcher) Index(score *models.Score, id string) error {
	s.Logger.Info("indexing document", slog.String("title", score.Title))

	doc := ScoreToDocument(score, id)
	resp, err := s.Meili.Index(scoresIndex).AddDocuments(doc)
	if err != nil {
		return err
	}

	_, err = s.waitForTask(resp.TaskUID, time.Duration(30)*time.Second)
	if err != nil {
		return err
	}
	return nil
}

func ScoreToDocument(score *models.Score, id string) map[string]interface{} {
	if score == nil {
		return nil
	}
	return map[string]interface{}{
		"id":          id,
		"title":       score.Title,
		"composers":   score.Composers,
		"lyricists":   score.Lyricists,
		"instruments": score.Instruments(),
	}
}

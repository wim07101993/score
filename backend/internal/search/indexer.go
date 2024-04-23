package search

import (
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"time"
)

const ScoresIndex = "scores"

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

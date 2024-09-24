package server

import (
	"context"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	grpcsearch "score/backend/api/generated/github.com/wim07101993/score/search"
	"score/backend/pkgs/persistence"
)

type SearcherServer struct {
	grpcsearch.SearcherServer
	logger   *slog.Logger
	searcher *meilisearch.Client
}

func NewSearcherServer(
	logger *slog.Logger,
	searcher *meilisearch.Client) *SearcherServer {
	return &SearcherServer{
		logger:   logger,
		searcher: searcher,
	}
}

func (serv *SearcherServer) SearchScores(_ context.Context, request *grpcsearch.SearchRequest) (*grpcsearch.SearchResponse, error) {
	result, err := serv.searcher.Index(persistence.ScoresIndexName).Search(
		request.Query,
		&meilisearch.SearchRequest{
			Offset: request.Offset,
			Limit:  request.Limit,
			Query:  request.Query,
		})

	if err != nil {
		return nil, err
	}

	scores := make([]*grpcsearch.Score, len(result.Hits), len(result.Hits))
	for i, hit := range result.Hits {
		if m, ok := hit.(map[string]interface{}); ok {
			if scores[i], err = ScoreFromDocument(m); err != nil {
				return nil, err
			}
		}
	}

	return &grpcsearch.SearchResponse{
		Scores:             scores,
		EstimatedTotalHits: result.EstimatedTotalHits,
	}, err
}

func ScoreFromDocument(m map[string]interface{}) (score *grpcsearch.Score, err error) {
	score = &grpcsearch.Score{}
	if id, ok := m["id"].(string); ok {
		score.Id = id
	}
	if title, ok := m["title"].(string); ok {
		score.Title = title
	}
	if composers, ok := m["composers"].([]string); ok {
		score.Composers = composers
	}
	if lyricists, ok := m["lyricists"].([]string); ok {
		score.Lyricists = lyricists
	}
	if instruments, ok := m["instruments"].([]string); ok {
		score.Instruments = instruments
	}
	return score, nil
}

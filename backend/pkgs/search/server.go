package search

import (
	"context"
	"errors"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
)

type SearcherServer struct {
	api.SearcherServer
	logger *slog.Logger
}

func NewSearcherServer(
	logger *slog.Logger) *SearcherServer {
	return &SearcherServer{
		logger: logger,
	}
}

func (serv *SearcherServer) SearchScores(_ context.Context, _ *api.SearchRequest) (*api.SearchResponse, error) {
	//result, err := serv.searcher.Index(persistence.ScoresIndexName).Search(
	//	request.Query,
	//	&meilisearch.SearchRequest{
	//		Offset: request.Offset,
	//		Limit:  request.Limit,
	//		Query:  request.Query,
	//	})
	//
	//if err != nil {
	//	return nil, err
	//}
	//
	//scores := make([]*grpcsearch.Score, len(result.Hits), len(result.Hits))
	//for i, hit := range result.Hits {
	//	if m, ok := hit.(map[string]interface{}); ok {
	//		if scores[i], err = ScoreFromDocument(m); err != nil {
	//			return nil, err
	//		}
	//	}
	//}
	//
	//return &grpcsearch.SearchResponse{
	//	Scores:             scores,
	//	EstimatedTotalHits: result.EstimatedTotalHits,
	//}, err
	return nil, errors.New("NOT IMPLEMENTED")
}

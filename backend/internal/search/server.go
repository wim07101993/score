package search

import (
	"errors"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/database"
)

type SearcherServer struct {
	api.SearcherServer
	logger *slog.Logger
	db     func() *database.ScoresDB
}

func NewSearcherServer(logger *slog.Logger) *SearcherServer {
	return &SearcherServer{
		logger: logger,
	}
}

func (serv *SearcherServer) GetScores(req *api.GetScoresRequest, srv api.Searcher_GetScoresServer) error {
	return errors.New("not implemented")
}

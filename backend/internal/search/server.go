package search

import (
	"context"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/database"
)

type SearcherServer struct {
	api.SearcherServer
	logger *slog.Logger
	db     database.ScoresDBFactory
}

func NewSearcherServer(logger *slog.Logger, db database.ScoresDBFactory) *SearcherServer {
	return &SearcherServer{
		logger: logger,
		db:     db,
	}
}

func (serv *SearcherServer) GetScore(ctx context.Context, request *api.GetScoreRequest) (*api.Score, error) {
	db, err := serv.db(ctx)
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "failed to connect to database")
	}

	score, err := db.GetScore(ctx, request.ScoreId)
	if err != nil {
		serv.logger.Error("failed to lookup score", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "failed to lookup score")
	}
	if score == nil {
		return nil, status.Error(codes.NotFound, "no score found with the given id")
	}

	return score, nil
}

func (serv *SearcherServer) GetAllScores(req *api.GetScoresRequest, srv api.Searcher_GetAllScoresServer) error {
	db, err := serv.db(srv.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		return status.Error(codes.Internal, "failed to connect to database")
	}

	pages := make(chan database.GetAllScoresResult, 2)
	done := make(chan int)

	if req.ChangedSince != nil {
		changedSince := req.ChangedSince.AsTime()
		err = db.GetAllScores(srv.Context(), req.PageSize, &changedSince, pages, done)
	} else {
		err = db.GetAllScores(srv.Context(), req.PageSize, nil, pages, done)
	}
	if err != nil {
		serv.logger.Error("failed to query all scores", slog.Any("error", err))
		return status.Error(codes.Internal, "failed to lookup score")
	}

	for {
		select {
		case val := <-pages:
			if val.Err != nil {
				serv.logger.Error("failed to query scores page", slog.Any("error", val.Err))
				return status.Error(codes.Internal, "failed to query scores page")
			}
			if err = srv.Send(val.Page); err != nil {
				serv.logger.Error("failed to respond scores page", slog.Any("error", err))
				return status.Error(codes.Internal, "failed to respond scores page")
			}
		case <-done:
			return nil
		}
	}

}

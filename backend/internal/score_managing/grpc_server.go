package score_managing

import (
	"context"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/database"
)

type ScoreManagerGrpcServer struct {
	api.ScoreManagerServer
	logger *slog.Logger
	db     database.ScoresDbFactory
}

func NewScoreManagerGrpcServer(logger *slog.Logger, db database.ScoresDbFactory) *ScoreManagerGrpcServer {
	return &ScoreManagerGrpcServer{
		logger: logger,
		db:     db,
	}
}

func (serv *ScoreManagerGrpcServer) Update(ctx context.Context, request *api.ScoreManager_UpdateServer) error {
	return nil
}

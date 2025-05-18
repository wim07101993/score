package search

import (
	"context"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"io"
	"log/slog"
	"math"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/blob"
	"score/backend/internal/database"
	"score/backend/internal/utils"
	"time"
)

type SearcherGrpcServer struct {
	api.SearcherServer
	logger *slog.Logger
	db     database.ScoresDbFactory
	blob   blob.MinioBlobStoreFactory
}

func NewSearcherGrpcServer(logger *slog.Logger, db database.ScoresDbFactory) *SearcherGrpcServer {
	return &SearcherGrpcServer{
		logger: logger,
		db:     db,
	}
}

func (serv *SearcherGrpcServer) GetScore(ctx context.Context, request *api.GetScoreRequest) (*api.Score, error) {
	db, err := serv.db(ctx)
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.String("error", err.Error()))
		return nil, status.Error(codes.Internal, "failed to connect to database")
	}
	defer db.ReleaseConnection()

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

func (serv *SearcherGrpcServer) GetScoreFile(req *api.GetScoreRequest, srv api.Searcher_GetScoreFileServer) error {
	blobs, err := serv.blob(srv.Context())
	if err != nil {
		serv.logger.Error("failed to connect to blob storage", slog.String("error", err.Error()))
		return status.Error(codes.Internal, "failed to connect to blob storage")
	}

	size, file, err := blobs.Get(srv.Context(), req.ScoreId)
	if err != nil {
		serv.logger.Error("failed to connect to blob storage", slog.String("error", err.Error()))
		return status.Error(codes.Internal, "failed to connect to blob storage")
	}

	defer func(file io.ReadCloser, logger *slog.Logger) {
		err := file.Close()
		if err != nil {
			logger.Error("failed to close blob file", slog.String("error", err.Error()))
		}
	}(file, serv.logger)

	_, err = io.Copy(utils.NewGrpcChunkWriter(srv, uint64(size)), file)
	return err
}

func (serv *SearcherGrpcServer) GetScores(req *api.GetScoresRequest, srv api.Searcher_GetScoresServer) error {
	db, err := serv.db(srv.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		return status.Error(codes.Internal, "failed to connect to database")
	}
	defer db.ReleaseConnection()

	var pageSize int32 = 10
	if req.PageSize != nil {
		pageSize = *req.PageSize
	}

	var changedSince *time.Time
	if req.ChangedSince != nil {
		t := req.ChangedSince.AsTime()
		changedSince = &t
	}

	count, err := db.GetScoresCount(srv.Context(), changedSince)
	if err != nil {
		serv.logger.Error("failed to get count of all scores", slog.Any("error", err))
		return status.Error(codes.Internal, "failed to lookup score")
	}

	if pageSize == 0 {
		// if no scores are requested, we do not need to go the database
		return nil
	}

	results, err := db.GetAllScores(srv.Context(), 0, changedSince)
	if err != nil {
		serv.logger.Error("failed to query all scores", slog.Any("error", err))
		return status.Error(codes.Internal, "failed to lookup score")
	}

	scores := make([]*api.Score, pageSize)
	var i int32
	for result := range results {
		if result.Err != nil {
			serv.logger.Error("failed to query scores page", slog.Any("error", result.Err))
			return status.Error(codes.Internal, "failed to query scores page")
		}

		scores[i] = result.Score
		i++
		if i == math.MaxInt32 || i >= pageSize {
			page := &api.ScoresPage{TotalHits: count, Scores: scores}
			if err = srv.Send(page); err != nil {
				serv.logger.Error("failed to respond scores page", slog.Any("error", err))
				return status.Error(codes.Internal, "failed to respond scores page")
			}
			scores = make([]*api.Score, pageSize)
			i = 0
		}
	}

	return nil
}

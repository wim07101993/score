package server

import (
	"context"
	"github.com/golang/protobuf/ptypes/empty"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/gitstorage"
	"time"
)

type Indexer struct {
	score.IndexerServer
	gitStore *gitstorage.GitFileStore
	logger   *slog.Logger
}

func NewIndexer(logger *slog.Logger, gitStore *gitstorage.GitFileStore) *Indexer {
	return &Indexer{
		logger:   logger,
		gitStore: gitStore,
	}
}

func (ix *Indexer) IndexScores(_ context.Context, request *score.IndexScoresRequest) (*empty.Empty, error) {
	err := ix.gitStore.Pull()
	if err != nil {
		ix.logger.Error("failed to get git work tree", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to pull git")
	}

	var since *time.Time
	if request.Since != nil {
		t := request.Since.AsTime()
		since = &t
	}
	var until *time.Time
	if request.Until != nil {
		t := request.Until.AsTime()
		until = &t
	}

	files, err := ix.gitStore.ChangedFiles(since, until)
	if err != nil {
		ix.logger.Error("failed to pull git", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to update scores repo")
	}

	ix.logger.Info("got changed git files", slog.Any("files", files))

	return &empty.Empty{}, nil
}

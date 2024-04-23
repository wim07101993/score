package server

import (
	"context"
	"encoding/xml"
	"github.com/golang/protobuf/ptypes/empty"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/index"
	"score/backend/internal/gitstorage"
	"score/backend/internal/search"
	"time"
)

type IndexerServer struct {
	index.IndexerServer
	gitStore *gitstorage.GitFileStore
	logger   *slog.Logger
	indexer  search.Indexer
}

func NewIndexerServer(
	logger *slog.Logger,
	gitStore *gitstorage.GitFileStore,
	indexer search.Indexer) *IndexerServer {
	return &IndexerServer{
		logger:   logger,
		gitStore: gitStore,
		indexer:  indexer,
	}
}

func (serv *IndexerServer) IndexScores(_ context.Context, request *index.IndexScoresRequest) (*empty.Empty, error) {
	err := serv.gitStore.Pull()
	if err != nil {
		serv.logger.Error("failed to get git work tree", slog.Any("error", err))
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

	newFiles, changed, removed, err := serv.gitStore.ChangedFiles(since, until)
	if err != nil {
		serv.logger.Error("failed to pull git", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to update scores repo")
	}

	serv.logger.Info("got changed git files",
		slog.Any("newFiles", newFiles),
		slog.Any("changed", changed),
		slog.Any("removed", removed))

	for _, f := range append(newFiles, changed...) {
		f := f
		go func() {
			serv.logger.Info("indexing score", slog.String("file", f.Name))
			id, err := gitstorage.ScoreIdFromPath(f.Name)
			if err != nil {
				serv.logger.Error("failed getting id from file name",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
			r, err := f.Reader()
			if err != nil {
				serv.logger.Error("failed to read file",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
			s, err := search.ParseScore(xml.NewDecoder(r))
			if err != nil {
				serv.logger.Error("failed to parse file",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
			err = serv.indexer.Index(s, id)
			if err != nil {
				serv.logger.Error("failed to index score",
					slog.String("file", f.Name),
					slog.Any("error", err))
				panic(err)
			}
		}()
	}

	for _, f := range removed {
		f := f
		go func() {
			serv.logger.Info("removing score", slog.String("file", f.Name))
			id, err := gitstorage.ScoreIdFromPath(f.Name)
			if err != nil {
				serv.logger.Error("failed getting id from file name",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
			err = serv.indexer.Remove(id)
			if err != nil {
				serv.logger.Error("failed to remove score",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
		}()
	}

	return &empty.Empty{}, nil
}

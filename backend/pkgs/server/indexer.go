package server

import (
	"context"
	"encoding/xml"
	"errors"
	"fmt"
	"github.com/go-git/go-git/v5/plumbing/object"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/index"
	"score/backend/pkgs/persistence"
	"strings"
	"time"
)

type IndexerServer struct {
	index.IndexerServer
	gitStore    *persistence.GitFileStore
	logger      *slog.Logger
	scoresIndex persistence.ScoresIndex
}

func NewIndexerServer(
	logger *slog.Logger,
	gitStore *persistence.GitFileStore,
	indexer persistence.ScoresIndex) *IndexerServer {
	return &IndexerServer{
		logger:      logger,
		gitStore:    gitStore,
		scoresIndex: indexer,
	}
}

func (serv *IndexerServer) IndexScores(_ context.Context, request *index.IndexScoresRequest) (*emptypb.Empty, error) {
	if err := validateIndexScoreRequest(request); err != nil {
		serv.logger.Debug("invalid index scores request", slog.Any("error", err))
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if err := serv.gitStore.Pull(); err != nil {
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
		go func(f *object.File) {
			serv.logger.Info("indexing score", slog.String("file", f.Name))
			if err := indexScore(serv.scoresIndex, f); err != nil {
				serv.logger.Error("failed to index score",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
		}(f)
	}

	for _, f := range removed {
		go func(f *object.File) {
			serv.logger.Info("removing score", slog.String("file", f.Name))
			if err := removeScore(serv.scoresIndex, f); err != nil {
				serv.logger.Error("failed to remove score",
					slog.String("file", f.Name),
					slog.Any("error", err))
			}
		}(f)
	}

	return &emptypb.Empty{}, nil
}

func validateIndexScoreRequest(request *index.IndexScoresRequest) error {
	builder := strings.Builder{}
	if request.Since == nil {
		builder.WriteString("'since' field must be specified. ")
	}
	if request.Until == nil {
		builder.WriteString("'until' field must be specified. ")
	} else if request.Until.AsTime().Before(time.Date(2024, 3, 7, 0, 0, 0, 0, time.UTC)) {
		builder.WriteString("until date is before 2024-03-07. There were no scores back then. ")
	}
	if builder.Len() > 0 {
		return errors.New(builder.String())
	}
	return nil
}

func indexScore(index persistence.ScoresIndex, file *object.File) error {
	r, err := file.Reader()
	if err != nil {
		return err
	}

	id, err := persistence.ScoreIdFromPath(file.Name)
	if err != nil {
		return fmt.Errorf("failed to get id from file name: %w", err)
	}

	s, err := persistence.ParseScore(xml.NewDecoder(r))
	if err != nil {
		return fmt.Errorf("failed to parse file: %w", err)
	}

	return index.AddScore(s, id)
}

func removeScore(index persistence.ScoresIndex, file *object.File) error {
	id, err := persistence.ScoreIdFromPath(file.Name)
	if err != nil {
		return fmt.Errorf("failed to get id from file name: %w", err)
	}
	return index.RemoveScore(id)
}

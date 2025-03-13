package indexing

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
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/blob"
	"score/backend/internal/database"
	"score/backend/internal/musicxml"
	"strings"
	"time"
)

type IndexerServer struct {
	api.IndexerServer
	gitStoreFactory blob.GitFileStoreFactory
	logger          *slog.Logger
	scoresDb        database.ScoresDbFactory
}

func NewIndexerServer(
	logger *slog.Logger,
	gitStore blob.GitFileStoreFactory,
	scoresDb database.ScoresDbFactory) *IndexerServer {
	return &IndexerServer{
		logger:          logger,
		gitStoreFactory: gitStore,
		scoresDb:        scoresDb,
	}
}

func (serv *IndexerServer) IndexScores(ctx context.Context, request *api.IndexScoresRequest) (*emptypb.Empty, error) {
	if err := validateIndexScoreRequest(request); err != nil {
		serv.logger.Debug("invalid index scores request", slog.Any("error", err))
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	gitStore, err := serv.gitStoreFactory(ctx)
	if err != nil {
		serv.logger.Debug("failed to initialize git store", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to init git-store")
	}

	if err := gitStore.Pull(); err != nil {
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

	newFiles, changed, removed, err := gitStore.ChangedFiles(since, until)
	if err != nil {
		serv.logger.Error("failed to pull git", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to update scores repo")
	}

	serv.logger.Info("got changed git files",
		slog.Any("newFiles", newFiles),
		slog.Any("changed", changed),
		slog.Any("removed", removed))

	db, err := serv.scoresDb(ctx)
	if err != nil {
		serv.logger.Error("failed to initialize scores db", slog.Any("error", err))
		return nil, status.Error(codes.Internal, "an internal error occurred: failed to initialize db")
	}

	for _, f := range append(newFiles, changed...) {
		serv.logger.Info("indexing score", slog.String("file", f.Name))
		if err := indexScore(ctx, db, f); err != nil {
			serv.logger.Error("failed to index score",
				slog.String("file", f.Name),
				slog.Any("error", err))
		}
	}

	for _, f := range removed {
		serv.logger.Info("removing score", slog.String("file", f.Name))
		if err := removeScore(ctx, db, f); err != nil {
			serv.logger.Error("failed to remove score",
				slog.String("file", f.Name),
				slog.Any("error", err))
		}
	}

	return &emptypb.Empty{}, nil
}

func validateIndexScoreRequest(request *api.IndexScoresRequest) error {
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

func indexScore(ctx context.Context, db *database.ScoresDb, file *object.File) error {
	r, err := file.Reader()
	if err != nil {
		return err
	}

	id, err := blob.ScoreIdFromPath(file.Name)
	if err != nil {
		return fmt.Errorf("failed to get id from file name: %w", err)
	}

	s, err := musicxml.DeserializeMusicXml(xml.NewDecoder(r))
	if err != nil {
		return fmt.Errorf("failed to parse file: %w", err)
	}

	return db.AddScore(ctx, id, s)
}

func removeScore(ctx context.Context, db *database.ScoresDb, file *object.File) error {
	id, err := blob.ScoreIdFromPath(file.Name)
	if err != nil {
		return fmt.Errorf("failed to get id from file name: %w", err)
	}
	return db.RemoveScore(ctx, id)
}

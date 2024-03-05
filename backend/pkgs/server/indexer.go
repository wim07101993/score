package server

import (
	"context"
	"github.com/golang/protobuf/ptypes/empty"
	"score/backend/api/generated/github.com/wim07101993/score"
)

type Indexer struct {
	score.IndexerServer
}

func (ix *Indexer) IndexScores(context.Context, *score.IndexScoresRequest) (*empty.Empty, error) {
	return &empty.Empty{}, nil
}

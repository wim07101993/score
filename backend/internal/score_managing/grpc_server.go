package score_managing

import (
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"io"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/blob"
	"score/backend/internal/database"
)

type ScoreManagerGrpcServer struct {
	api.ScoreManagerServer
	logger *slog.Logger
	db     database.ScoresDbFactory
	blob   blob.MinioBlobStoreFactory
}

func NewScoreManagerGrpcServer(logger *slog.Logger, db database.ScoresDbFactory) *ScoreManagerGrpcServer {
	return &ScoreManagerGrpcServer{
		logger: logger,
		db:     db,
	}
}

func (serv *ScoreManagerGrpcServer) Update(srv api.ScoreManager_UpdateScoreServer) error {
	db, err := serv.db(srv.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.String("error", err.Error()))
		return status.Error(codes.Internal, "failed to connect to database")
	}
	defer db.ReleaseConnection()

	r := UpdateRequestReader{requestStream: srv}
	blob, err := serv.blob(srv.Context())

	blob.Put(srv.Context(), r)
	return nil
}

type UpdateRequestReader struct {
	requestStream api.ScoreManager_UpdateScoreServer
	buffer        []byte
	totalFileSize int64
	scoreId       string
}

func (rs *UpdateRequestReader) Read(p []byte) (n int, err error) {
	if len(rs.buffer) == 0 {
		chunk, err := rs.requestStream.Recv()
		if err != nil {
			return 0, err
		}
		if rs.totalFileSize == 0 {
			rs.totalFileSize = chunk.TotalFileSize
		}
		if rs.scoreId == "" {
			rs.scoreId = chunk.ScoreId
		}
		rs.buffer = chunk.FileChunk
	}

	n = copy(rs.buffer, p)
	rs.buffer = rs.buffer[n:]
	return n, err
}

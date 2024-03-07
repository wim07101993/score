package main

import (
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/gitstorage"
	grpc2 "score/backend/internal/grpc"
	"score/backend/pkgs/server"
)

func startIndexerServer() {
	gitStore := gitstorage.NewGitStore(logger, "git@github.com:wim07101993/scores.git")

	logger.Info("starting grpc server")
	addr := fmt.Sprintf(":%d", serverPort)
	list, err := net.Listen("tcp", addr)
	if err != nil {
		logger.Error("failed to listen for requests",
			slog.Any("error", err),
			slog.String("address", addr))
		os.Exit(1)
	}

	grpcLogger := grpc2.NewLogger(logger)
	s := grpc.NewServer(
		grpc.ChainUnaryInterceptor(logging.UnaryServerInterceptor(grpcLogger)),
		grpc.ChainStreamInterceptor(logging.StreamServerInterceptor(grpcLogger)))

	indexer := server.NewIndexer(logger, gitStore)
	score.RegisterIndexerServer(s, indexer)
	reflection.Register(s)

	if err := s.Serve(list); err != nil {
		logger.Error("failed to serve score indexer",
			slog.Any("error", err),
			slog.String("address", addr))
	}
}

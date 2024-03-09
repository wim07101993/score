package main

import (
	"flag"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"github.com/meilisearch/meilisearch-go"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/gitstorage"
	grpc2 "score/backend/internal/grpc"
	"score/backend/internal/search"
	"score/backend/pkgs/server"
)

var file string
var meiliConfig meilisearch.ClientConfig
var serverPort int

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var indexer search.Indexer

func init() {
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700", "The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "", "The api key with which to connect to the meili server.")
	flag.IntVar(&serverPort, "port", 0, "The port on which the server should listen. If omitted, stdin is used.")
}

func main() {
	flag.Parse()

	indexer = search.NewIndexer(logger, meilisearch.NewClient(meiliConfig))

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

	indexerServer := server.NewIndexerServer(logger, gitStore, indexer)
	score.RegisterIndexerServer(s, indexerServer)
	reflection.Register(s)

	if err := s.Serve(list); err != nil {
		logger.Error("failed to serve score indexer",
			slog.Any("error", err),
			slog.String("address", addr))
	}
}

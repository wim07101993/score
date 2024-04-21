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
	"strconv"
)

const (
	meiliHostEnvVar        = "MEILI_HOST"
	meiliApiKeyEnvVar      = "MEILI_API_KEY"
	scoresRepositoryEnvVar = "SCORES_REPOSITORY"
	scorePortEnvVar        = "SCORE_PORT"
)

var gitConfig gitstorage.Config
var meiliConfig meilisearch.ClientConfig
var serverPort int

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var indexer search.Indexer

func init() {
	flag.StringVar(&gitConfig.Repository, "repo", "", "The git repository on which the scores are stored. Ensure this server has read access to that repo.")
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700", "The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "", "The api key with which to connect to the meili server.")
	flag.IntVar(&serverPort, "port", 7701, "The port on which the server should listen. If omitted, stdin is used.")

	gitConfig.Repository = os.Getenv(scoresRepositoryEnvVar)
	meiliConfig.Host = os.Getenv(meiliHostEnvVar)
	meiliConfig.APIKey = os.Getenv(meiliApiKeyEnvVar)

	sport := os.Getenv(scorePortEnvVar)
	if sport != "" {
		p, err := strconv.Atoi(os.Getenv(scorePortEnvVar))
		if err != nil {
			panic(err)
		}
		serverPort = p
	}
}

func main() {
	flag.Parse()
	validateVars()

	indexer = search.NewIndexer(logger, meilisearch.NewClient(meiliConfig))

	gitStore := gitstorage.NewGitStore(logger, gitConfig.Repository)

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

func validateVars() {
	if meiliConfig.Host == "" {
		panic("no host specified for meili. e.g.: --host http://localhost:7700 or " + meiliHostEnvVar + " environment variable")
	}
	if meiliConfig.APIKey == "" {
		panic("no meili api key specified. e.g.: --apikey MY_API_KEY or " + meiliApiKeyEnvVar + " environment variable")
	}
	if gitConfig.Repository == "" {
		panic("no git repo specified. e.g.: --repo git@SERVER.com:MY_USER/REPOSITORY.git or " + scoresRepositoryEnvVar + " environment variable")
	}
	if serverPort < 80 {
		panic("cannot listen on a port lower than 80. e.g.: --port 7701 or " + scorePortEnvVar + " environment variable")
	}
}

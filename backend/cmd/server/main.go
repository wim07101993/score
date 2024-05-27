package main

import (
	"flag"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	meili "github.com/meilisearch/meilisearch-go"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score/index"
	"score/backend/api/generated/github.com/wim07101993/score/search"
	auth2 "score/backend/pkgs/auth"
	"score/backend/pkgs/interceptors"
	"score/backend/pkgs/persistence"
	"score/backend/pkgs/server"
	"strconv"
)

const (
	meiliHostEnvVar        = "MEILI_HOST"
	meiliApiKeyEnvVar      = "MEILI_API_KEY"
	scoresRepositoryEnvVar = "SCORES_REPOSITORY"
	scorePortEnvVar        = "SCORE_PORT"
)

var scoresRepository string
var meiliConfig meili.ClientConfig
var serverPort int

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var indexer persistence.Indexer

func init() {
	flag.StringVar(&scoresRepository, "repo", "", "The git repository on which the scores are stored. Ensure this server has read access to that repo.")
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700", "The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "", "The api key with which to connect to the meili server.")
	flag.IntVar(&serverPort, "port", 7701, "The port on which the server should listen. If omitted, stdin is used.")

	scoresRepository = os.Getenv(scoresRepositoryEnvVar)
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

	logger.Info("starting grpc server")
	addr := fmt.Sprintf(":%d", serverPort)
	list, err := net.Listen("tcp", addr)
	if err != nil {
		logger.Error("failed to listen for requests",
			slog.Any("error", err),
			slog.String("address", addr))
		os.Exit(1)
	}

	jwkCache, err := auth2.CreateJwkCache()
	if err != nil {
		logger.Error("failed to create jwk cache")
		panic(err)
	}
	jwkSets := auth2.JwkCachedSets(jwkCache)

	grpcLogger := interceptors.NewLogger(logger)
	authMiddleware := interceptors.EnsureContextAuthenticated(jwkSets)
	serv := grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			logging.UnaryServerInterceptor(grpcLogger),
			auth.UnaryServerInterceptor(authMiddleware),
		),
		grpc.ChainStreamInterceptor(
			logging.StreamServerInterceptor(grpcLogger),
			auth.StreamServerInterceptor(authMiddleware),
		),
	)

	meiliClient := meili.NewClient(meiliConfig)
	indexer = persistence.NewIndexer(logger, meiliClient)
	gitStore := persistence.NewGitStore(logger, scoresRepository)

	indexerServer := server.NewIndexerServer(logger, gitStore, indexer)
	searchServer := server.NewSearcherServer(logger, meiliClient)

	index.RegisterIndexerServer(serv, indexerServer)
	search.RegisterSearcherServer(serv, searchServer)
	reflection.Register(serv)

	if err := serv.Serve(list); err != nil {
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
	if scoresRepository == "" {
		panic("no git repo specified. e.g.: --repo git@SERVER.com:MY_USER/REPOSITORY.git or " + scoresRepositoryEnvVar + " environment variable")
	}
	if serverPort < 80 {
		panic("cannot listen on a port lower than 80. e.g.: --port 7701 or " + scorePortEnvVar + " environment variable")
	}
}

package main

import (
	"flag"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/auth"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	meili "github.com/meilisearch/meilisearch-go"
	"golang.org/x/exp/maps"
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
	"strings"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

func main() {
	flag.Parse()
	parseEnvVars()
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

	jwkCache, err := auth2.CreateJwkCache(authConfigs)
	if err != nil {
		logger.Error("failed to create jwk cache")
		panic(err)
	}
	jwkSets := auth2.JwkCachedSets(authConfigs, jwkCache)

	grpcLogger := interceptors.NewLogger(logger)
	authMiddleware, err := interceptors.EnsureContextAuthenticated(jwkSets)
	if err != nil {
		panic(err)
	}

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
	indexes := persistence.NewMeiliIndexes(logger, meiliClient)
	gitStore := persistence.NewGitFileStore(logger, scoresRepository)

	indexerServer := server.NewIndexerServer(logger, gitStore, indexes)
	searchServer := server.NewSearcherServer(logger, meiliClient)

	index.RegisterIndexerServer(serv, indexerServer)
	search.RegisterSearcherServer(serv, searchServer)
	reflection.Register(serv)

	if err := serv.Serve(list); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err),
			slog.String("address", addr))
	}
}

func parseEnvVars() {
	if scoresRepository == "" {
		scoresRepository = os.Getenv(scoresRepositoryEnvVar)
	}
	if meiliConfig.Host == "" {
		meiliConfig.Host = os.Getenv(meiliHostEnvVar)
	}
	if meiliConfig.APIKey == "" {
		meiliConfig.APIKey = os.Getenv(meiliApiKeyEnvVar)
	}

	if serverPort == 0 {
		sport := os.Getenv(scorePortEnvVar)
		if sport != "" {
			p, err := strconv.Atoi(os.Getenv(scorePortEnvVar))
			if err != nil {
				panic(err)
			}
			serverPort = p
		}
	}

	if authProviderCsvList == "" {
		authProviderCsvList = os.Getenv(authProvidersEnvVars)
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
	if authProviderCsvList == "" {
		panic("no auth providers specified. e.g.: --auth google,facebook")
	}

	if authProviderCsvList == "none" {
		// This should only be used for debugging purposes!
		interceptors.SkipJwtVerification = true
	} else {
		authProviders := strings.Split(authProviderCsvList, ",")
		if len(authProviders) == 0 {
			panic("no auth providers specified. e.g.: --auth google,facebook")
		}

		for _, provider := range authProviders {
			if c, ok := knownAuthConfigs[provider]; ok {
				authConfigs = append(authConfigs, c)
				continue
			}
			panic("unknown auth provider: " + provider + "known auth providers" + strings.Join(maps.Keys(knownAuthConfigs), ", "))
		}
	}
}

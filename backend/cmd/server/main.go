package main

import (
	"fmt"
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"net/http"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/pkgs/auth"
	"score/backend/pkgs/blob"
	"score/backend/pkgs/indexing"
	"score/backend/pkgs/logging"
	"score/backend/pkgs/search"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var cfg Config

func main() {
	if err := cfg.FromFile(); err != nil {
		panic(err)
	}
	if err := cfg.FromEnv(); err != nil {
		panic(err)
	}
	if err := cfg.Validate(); err != nil {
		panic(err)
	}

	c := make(chan struct{}, 1)
	go func() {
		serveGrpc()
		c <- struct{}{}
	}()

	go func() {
		serveHttp()
		c <- struct{}{}
	}()

	<-c
}

func serveGrpc() {
	logger.Info("starting gRPC server")
	gitStore := blob.NewGitFileStore(logger, cfg.ScoresRepository)

	_, searchDb := createDb()

	indexerServer := indexing.NewIndexerServer(logger, gitStore, searchDb)
	searchServer := search.NewSearcherServer(logger)

	authConfigs, err := cfg.AuthConfigs()
	if err != nil {
		logger.Error("failed to load auth configs")
		panic(err)
	}

	jwkCache, err := auth.CreateJwkCache(authConfigs)
	if err != nil {
		logger.Error("failed to create jwk cache")
		panic(err)
	}

	jwkSets := auth.JwkCachedSets(authConfigs, jwkCache)
	authUnaryInterceptor, err := auth.AuthUnaryInterceptor(jwkSets)
	if err != nil {
		panic(err)
	}

	authStreamInterceptor, err := auth.AuthStreamInterceptor(jwkSets)
	if err != nil {
		panic(err)
	}

	serv := grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			logging.LoggingUnaryInterceptor(logger),
			authUnaryInterceptor,
		),
		grpc.ChainStreamInterceptor(
			logging.LoggingStreamInterceptor(logger),
			authStreamInterceptor,
		),
	)

	api.RegisterIndexerServer(serv, indexerServer)
	api.RegisterSearcherServer(serv, searchServer)
	reflection.Register(serv)

	addr := fmt.Sprintf(":%d", cfg.GrpcServerPort)
	list, err := net.Listen("tcp", addr)
	if err != nil {
		logger.Error("failed to listen for requests",
			slog.Any("error", err),
			slog.String("address", addr))
		return
	}
	defer func() {
		if err := list.Close(); err != nil {
			logger.Error("failed to close grpc server",
				slog.Any("error", err))
		}
	}()

	logger.Info("start listening for gRPC requests")

	if err := serv.Serve(list); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err),
			slog.String("address", addr))
	}
}

func serveHttp() {
	logger.Info("starting http server")
	serv := auth.NewAuthorizerServer(logger)
	serv.RegisterRoutes()

	addr := fmt.Sprintf(":%d", cfg.HttpServerPort)
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err))
	}
}

func createDb() (auth.UsersDb, search.Db) {
	db, err := sqlx.Connect("sqlite3", "score.db")
	if err != nil {
		panic(err)
	}

	userDb := auth.NewUsersDb(logger, db)
	searchDb := search.NewDb(logger, db)

	if cfg.InitialUserAdminEmailAddress != "" {
		if err = userDb.EnsureUserAdmin(cfg.InitialUserAdminEmailAddress); err != nil {
			panic(err)
		}
	}

	return userDb, searchDb
}

package main

import (
	"flag"
	"fmt"
	"github.com/jmoiron/sqlx"
	"github.com/lestrrat-go/jwx/v2/jwk"
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

func main() {
	flag.Parse()
	parseEnvVars()
	validateConfig()

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
	gitStore := blob.NewGitFileStore(logger, scoresRepository)

	_, searchDb := createDb()

	indexerServer := indexing.NewIndexerServer(logger, gitStore, searchDb)
	searchServer := search.NewSearcherServer(logger)

	jwkCache, err := auth.CreateJwkCache(authConfigs)
	if err != nil {
		logger.Error("failed to create jwk cache")
		panic(err)
	}

	jwkSets := auth.JwkCachedSets(authConfigs, jwkCache)
	serv := createGrpcServer(jwkSets)

	api.RegisterIndexerServer(serv, indexerServer)
	api.RegisterSearcherServer(serv, searchServer)
	reflection.Register(serv)

	addr := fmt.Sprintf(":%d", serverPort)
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
	serv := auth.NewAuthorizerServer(logger)
	serv.RegisterRoutes()

	if err := http.ListenAndServe("1234", nil); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err))
	}
}

func createGrpcServer(jwkSets map[string]jwk.Set) *grpc.Server {
	authUnaryInterceptor, err := auth.AuthUnaryInterceptor(jwkSets)
	if err != nil {
		panic(err)
	}

	authStreamInterceptor, err := auth.AuthStreamInterceptor(jwkSets)
	if err != nil {
		panic(err)
	}

	return grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			logging.LoggingUnaryInterceptor(logger),
			authUnaryInterceptor,
		),
		grpc.ChainStreamInterceptor(
			logging.LoggingStreamInterceptor(logger),
			authStreamInterceptor,
		),
	)

}

func createDb() (auth.UsersDb, search.Db) {
	db, err := sqlx.Connect("sqlite3", "score.db")
	if err != nil {
		panic(err)
	}

	userDb := auth.NewUsersDb(logger, db)
	searchDb := search.NewDb(logger, db)

	if err = userDb.EnsureUserAdmin(initialUserAdminEmailAddress); err != nil {
		panic(err)
	}

	return userDb, searchDb
}

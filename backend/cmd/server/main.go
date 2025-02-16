package main

import (
	"context"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"net/http"
	"os"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/auth"
	"score/backend/internal/blob"
	"score/backend/internal/database"
	"score/backend/internal/indexing"
	"score/backend/internal/logging"
	"score/backend/internal/search"
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
var cfg Config
var pgPool *pgxpool.Pool

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
	logger.Debug("starting application with config", slog.Any("config", cfg))

	var err error
	pgPool, err = pgxpool.New(context.Background(), cfg.DbConnectionString)
	if err != nil {
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

	indexerServer := indexing.NewIndexerServer(logger, createGitBlobStore, createScoresDb)
	searchServer := search.NewSearcherServer(logger)

	jwkSet, err := auth.CreateJwkCache(cfg.JwtIssuer)
	if err != nil {
		logger.Error("failed to create jwk cache")
		panic(err)
	}

	authUnaryInterceptor, err := auth.UnaryInterceptor(cfg.JwtIssuer, jwkSet)
	if err != nil {
		panic(err)
	}

	authStreamInterceptor, err := auth.StreamInterceptor(cfg.JwtIssuer, jwkSet)
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

	logger.Info("start listening for grpc requests", slog.String("addr", addr))

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
	logger.Info("start listening for http requests", slog.String("addr", addr))
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err))
	}
}

func createGitBlobStore(ctx context.Context) (*blob.GitFileStore, error) {
	return blob.NewGitFileStore(ctx, logger, cfg.ScoresRepository), nil
}

func createScoresDb(ctx context.Context) (*database.ScoresDB, error) {
	pgConn, err := pgPool.Acquire(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create database connection")
	}
	return database.NewScoresDB(logger, pgConn), nil
}

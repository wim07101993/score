package main

import (
	"bufio"
	"encoding/xml"
	"flag"
	"fmt"
	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
	"github.com/meilisearch/meilisearch-go"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"score/backend/api/generated/github.com/wim07101993/score"
	"score/backend/internal/gitstorage"
	grpc2 "score/backend/internal/grpc"
	"score/backend/internal/search"
	"score/backend/pkgs/musicxml"
	"score/backend/pkgs/server"
)

var file string
var meiliConfig meilisearch.ClientConfig
var serverPort int

var logger = slog.Default()
var indexer search.Indexer

func init() {
	flag.StringVar(&file, "file", "", "The file to parse. If omitted, stdin is used.")
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700", "The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "", "The api key with which to connect to the meili server.")
	flag.IntVar(&serverPort, "port", 0, "The port on which the server should listen. If omitted, stdin is used.")
}

func main() {
	flag.Parse()

	indexer = search.NewIndexer(logger, meilisearch.NewClient(meiliConfig))

	if file != "" {
		indexScore(file)
		return
	}

	if serverPort > 0 {
		startIndexerServer()
		return
	}

	indexScoresFromStdin()
}

func indexScore(path string) {
	logger.Info("indexing file",
		slog.String("file", path))

	file, err := os.Open(path)
	if err != nil {
		logger.Error("failed to read file", slog.Any("error", err))
		return
	}

	id, err := gitstorage.ScoreIdFromPath(path)

	s, err := musicxml.NewParser(xml.NewDecoder(file)).Parse()
	if err != nil {
		logger.Error("failed to parse score",
			slog.Any("error", err),
			slog.String("file", path))
		return
	}

	err = indexer.Index(s, id)
	if err != nil {
		logger.Error("failed to index score",
			slog.Any("error", err),
			slog.Any("score", s),
			slog.String("file", path))
		return
	}
}

func indexScoresFromStdin() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Split(bufio.ScanLines)
	for scanner.Scan() {
		file := scanner.Text()
		ext := filepath.Ext(file)
		switch ext {
		case "":
			slog.Warn("file without extension, ignoring", slog.String("file", file))
		case ".xml", ".musicxml":
			go indexScore(file)
		default:
			slog.Warn("unknown file extension, ignoring",
				slog.String("file", file),
				slog.String("extension", ext))
		}

	}
	if err := scanner.Err(); err != nil {
		logger.Error("failed reading stdin", slog.Any("error", err))
		os.Exit(1)
	}
}

func startIndexerServer() {
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

	score.RegisterIndexerServer(s, &server.Indexer{})
	reflection.Register(s)

	if err := s.Serve(list); err != nil {
		logger.Error("failed to serve score indexer",
			slog.Any("error", err),
			slog.String("address", addr))
	}
}

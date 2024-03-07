package main

import (
	"flag"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"os"
	"score/backend/internal/search"
)

var file string
var meiliConfig meilisearch.ClientConfig
var serverPort int

var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
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

package main

import (
	"bufio"
	"encoding/xml"
	"flag"
	"github.com/meilisearch/meilisearch-go"
	"log/slog"
	"os"
	"path/filepath"
	"score/backend/internal/gitstorage"
	"score/backend/internal/search"
	"score/backend/pkgs/musicxml"
)

var file string
var meiliConfig meilisearch.ClientConfig

var logger = slog.Default()
var indexer search.Indexer

func main() {
	parseFlags()

	indexer = search.NewIndexer(logger, meilisearch.NewClient(meiliConfig))

	if file != "" {
		indexScore(file)
		return
	}

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

func indexScore(path string) {
	logger.Info("indexing file",
		slog.String("file", path))

	file, err := os.Open(path)
	if err != nil {
		logger.Error("failed to read file", slog.Any("error", err))
		return
	}

	id, err := gitstorage.ScoreIdFromPath(path)

	score, err := musicxml.NewParser(xml.NewDecoder(file)).Parse()
	if err != nil {
		logger.Error("failed to parse score",
			slog.Any("error", err),
			slog.String("file", path))
		return
	}

	err = indexer.Index(score, id)
	if err != nil {
		logger.Error("failed to index score",
			slog.Any("error", err),
			slog.Any("score", score),
			slog.String("file", path))
		return
	}
}

func parseFlags() {
	flag.Parse()
	flag.StringVar(&file, "file", "", "The file to parse. If omitted, stdin is used.")
	flag.StringVar(&meiliConfig.Host, "host", "http://localhost:7700", "The meili search server on which to index the score.")
	flag.StringVar(&meiliConfig.APIKey, "apikey", "", "The api key with which to connect to the meili server.")
}

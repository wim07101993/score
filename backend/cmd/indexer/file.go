package main

import (
	"encoding/xml"
	"log/slog"
	"os"
	"score/backend/internal/gitstorage"
	"score/backend/pkgs/musicxml"
)

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

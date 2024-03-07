package main

import (
	"bufio"
	"log/slog"
	"os"
	"path/filepath"
)

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

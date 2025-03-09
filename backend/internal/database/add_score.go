package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"log/slog"
	"score/backend/internal/musicxml"
	"time"
)

func (db *ScoresDB) AddScore(ctx context.Context, id string, score *musicxml.ScorePartwise) error {
	db.logger.Info("indexing score document",
		slog.String("title", score.Work.Title),
		slog.String("id", id))

	var composers []string
	var lyricists []string
	for _, creator := range score.Identification.Creators {
		switch creator.Type {
		case "composer":
			composers = append(composers, creator.Value)
		case "lyricist":
			composers = append(lyricists, creator.Value)
		}
	}

	var instruments []string
	for _, part := range score.PartList {
		if part.ScorePart == nil {
			continue
		}
		for _, instrument := range part.ScorePart.Instruments {
			if instrument.Sound == "" {
				continue
			}
			instruments = append(instruments, instrument.Sound)
		}
	}

	const query = `
		INSERT INTO scores (
			id, 
			work_title, work_number, 
			movement_title, movement_number, 
			creators_composers, creators_lyricists, 
			languages, instruments, 
			lastChangedAt, tags) 
		VALUES (
			@id, 
			@work_title, @work_number, 
			@movement_title, @movement_number, 
			@creators_composers, @creators_lyricists, 
			@languages, @instruments, 
			@lastChangedAt, @tags)
		ON CONFLICT (id) DO UPDATE SET 
			work_title = EXCLUDED.work_title,
			work_number = EXCLUDED.work_number,
			movement_title = EXCLUDED.movement_title,
			movement_number = EXCLUDED.movement_number,
			creators_composers = EXCLUDED.creators_composers,
			creators_lyricists = EXCLUDED.creators_lyricists,
			languages = EXCLUDED.languages,
			instruments = EXCLUDED.instruments,
			lastChangedAt = EXCLUDED.lastChangedAt,
			tags = EXCLUDED.tags`

	db.logger.Debug("Executing query", slog.String("query", query))
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{
		"id":                 id,
		"work_title":         score.Work.Title,
		"work_number":        score.Work.Number,
		"movement_title":     score.MovementTitle,
		"movement_number":    score.MovementNumber,
		"creators_composers": composers,
		"creators_lyricists": lyricists,
		"languages":          []string{score.Defaults.LyricLanguage},
		"instruments":        instruments,
		"lastChangedAt":      time.Now().UTC(),
	})
	return err
}

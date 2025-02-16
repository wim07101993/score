package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"score/backend/internal/musicxml"
	"time"
)

type ScoresDB struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewScoresDB(logger *slog.Logger, conn *pgxpool.Conn) *ScoresDB {
	return &ScoresDB{
		logger: logger,
		conn:   conn,
	}
}

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

	const insertScoreQuery = `
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
			@lastChangedAt, @tags)`

	_, err := db.conn.Exec(ctx, insertScoreQuery, pgx.NamedArgs{
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

func (db *ScoresDB) RemoveScore(ctx context.Context, id string) error {
	db.logger.Info("removing score document", slog.String("id", id))

	const query = `DELETE FROM scores WHERE id = @id`
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{"id": id})
	return err
}

func (db *ScoresDB) GetAllScores(ctx context.Context, userId string) ([]musicxml.ScorePartwise, error) {
	db.logger.Info("getting score page")

	const query = `
		SELECT 
			score.id, 
			score.work_title,
			score.work_number,
			score.movement_number,
			score.movement_title,
			score.creators_composers,
			score.creators_lyricists,
			score.languages,
			score.instruments,
			score.lastChangedAt,
			score.tags,
			favourite.favouritedAt
		FROM scores AS score
		LEFT JOIN (
			SELECT favourite.favouritedAt, favourite.scoreId 
			FROM favourites AS favourite 
			WHERE favourite.userId = @userId
		) as favourite ON score.id = favourite.scoreId
		ORDER BY lastChangedAt DESC`

	rows, err := db.conn.Query(ctx, query, pgx.NamedArgs{"userId": userId})
	defer rows.Close()

	if err != nil {
		return nil, err
	}

	for rows.Next() {
		// TODO
		//rows.StructScan()
	}

	//TODO
	return nil, nil
}

package search

import (
	"github.com/jmoiron/sqlx"
	"log/slog"
)

type Db interface {
	AddScore(score *Score, id string) error
	RemoveScore(id string) error
}

type searchDb struct {
	logger *slog.Logger
	db     *sqlx.DB
}

func NewDb(logger *slog.Logger, db *sqlx.DB) Db {
	return &searchDb{
		logger: logger,
		db:     db,
	}
}

func (db *searchDb) AddScore(score *Score, id string) error {
	db.logger.Info("indexing score document",
		slog.String("title", score.Title),
		slog.String("id", id))

	const insertScoreQuery = `
		INSERT INTO scores (id, title)
		VALUES (:id, :title)`
	_, err := db.db.NamedExec(insertScoreQuery, map[string]interface{}{
		"id":          id,
		"title":       score.Title,
		"composers":   score.Composers,
		"lyricists":   score.Lyricists,
		"instruments": score.Instruments,
	})

	if err != nil {
		return err
	}
	return nil
}

func (db *searchDb) RemoveScore(id string) error {
	db.logger.Info("removing score document", slog.String("id", id))

	const query = `DELETE FROM scores WHERE id = :id`
	_, err := db.db.Exec(query, map[string]interface{}{"id": id})
	return err
}

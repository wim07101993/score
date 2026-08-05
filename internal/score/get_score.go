package score

import (
	"context"
	"errors"
	"log/slog"

	"github.com/jackc/pgx/v5"
)

// GetScore reads the metadata of one score. It answers ErrScoreNotFound when
// nothing is stored under the given id.
func (db *Database) GetScore(ctx context.Context, scoreId string) (*Score, error) {
	db.logger.Info("getting score", slog.String("scoreId", scoreId))

	row := db.conn.QueryRow(ctx, getScoreQuery, scoreId)
	score, err := scanScore(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrScoreNotFound
		}
		return nil, err
	}

	return score, nil
}

// GetScoreMusicXml reads the document one score's metadata was extracted from.
// It answers ErrScoreNotFound when nothing is stored under the given id.
func (db *Database) GetScoreMusicXml(ctx context.Context, scoreId string) (string, error) {
	db.logger.Info("getting music-xml", slog.String("scoreId", scoreId))

	row := db.conn.QueryRow(ctx, getScoreMusicXmlQuery, scoreId)

	var (
		id      string
		content string
	)

	err := row.Scan(&id, &content)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", ErrScoreNotFound
		}
		return "", err
	}

	return content, nil
}

const getScoreQuery = `
	SELECT
		score.id,
		score.work_title,
		score.work_number,
		score.movement_number,
		score.movement_title,
		score.lastChangedAt,
		score.creators_composers,
		score.creators_lyricists,
		score.languages,
		score.instruments,
		score.tags
	FROM scores AS score
	WHERE score.id = $1
`

const getScoreMusicXmlQuery = `
	SELECT
		score.id,
		score.content
	FROM score_files AS score
	WHERE score.id = $1
`

package score

import (
	"context"
	"time"
)

// GetScores reads the metadata of every score that changed within the given
// window, newest first.
func (db *Database) GetScores(
	ctx context.Context,
	changesSince time.Time,
	changesUntil time.Time) ([]*Score, error) {
	db.logger.Info("getting scores")

	rows, err := db.conn.Query(ctx, getScoresQuery, changesSince, changesUntil)

	if err != nil {
		return nil, err
	}

	var scores = make([]*Score, 0)

	defer rows.Close()
	for rows.Next() {
		score, err := scanScore(rows)
		if err != nil {
			return scores, err
		}

		scores = append(scores, score)
	}

	return scores, err
}

const getScoresQuery = `
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
	WHERE score.lastchangedat >= $1 AND score.lastchangedat <= $2
	ORDER BY score.lastchangedat DESC
`

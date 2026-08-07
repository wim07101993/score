package score

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

// List reads the metadata of every score that changed within the given
// window, newest first.
func List(
	ctx context.Context,
	db *pgxpool.Conn,
	changesSince time.Time,
	changesUntil time.Time,
) ([]*Score, error) {
	slogctx.Info(ctx, "getting scores")

	rows, err := db.Query(ctx, getScoresQuery, changesSince, changesUntil)
	if err != nil {
		return nil, fmt.Errorf("failed to query database: %w", err)
	}

	var scores = make([]*Score, 0)

	defer rows.Close()
	for rows.Next() {
		score, err := scanScore(rows)
		if err != nil {
			return scores, fmt.Errorf("failed to scan score db row: %w", err)
		}

		scores = append(scores, score)
	}

	return scores, nil
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

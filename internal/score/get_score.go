package score

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

// Get reads the metadata of one score. It answers ErrScoreNotFound when
// nothing is stored under the given id.
func Get(ctx context.Context, db *pgxpool.Conn, scoreId string) (*Score, error) {
	slogctx.Info(ctx, "getting score", slog.String("scoreId", scoreId))

	row := db.QueryRow(ctx, getScoreQuery, scoreId)
	score, err := scanScore(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrScoreNotFound
		}
		return nil, fmt.Errorf("failed to scan score db row: %w", err)
	}

	return score, nil
}

// GetMusicXml reads the document one score's metadata was extracted from.
// It answers ErrScoreNotFound when nothing is stored under the given id.
func GetMusicXml(ctx context.Context, db *pgxpool.Conn, scoreId string) (string, error) {
	slogctx.Info(ctx, "getting music-xml", slog.String("scoreId", scoreId))

	row := db.QueryRow(ctx, getScoreMusicXmlQuery, scoreId)

	var (
		id      string
		content string
	)

	err := row.Scan(&id, &content)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", ErrScoreNotFound
		}
		return "", fmt.Errorf("failed to scan score musicxml db row: %w", err)
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

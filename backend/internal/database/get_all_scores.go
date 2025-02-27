package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"iter"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"strconv"
	"time"
)

type ScoreResult struct {
	Score *api.Score
	Err   error
}

func (db *ScoresDB) GetScoresCount(
	ctx context.Context,
	changedSince *time.Time) (int64, error) {
	db.logger.Info("getting score count")

	countQuery := `SELECT COUNT(*) FROM scores`
	var params []any

	if changedSince != nil {
		countQuery += " WHERE score.lastchangedat >= $1 "
		params = append(params, changedSince)
	}

	var count int64
	err := db.conn.QueryRow(ctx, countQuery).Scan(&count)
	return count, err
}

func (db *ScoresDB) GetAllScores(
	ctx context.Context,
	skip int,
	changedSince *time.Time) (iter.Seq[ScoreResult], error) {
	db.logger.Info("getting score page")

	var rows pgx.Rows

	scoresQuery := apiScoreSelect
	var params []any

	if changedSince != nil {
		scoresQuery += " WHERE score.lastchangedat >= $1 "
		params = append(params, changedSince)
	}
	if skip != 0 {
		scoresQuery += " SKIP " + strconv.Itoa(skip)
	}
	scoresQuery = scoresQuery + " ORDER BY lastChangedAt DESC "

	rows, err := db.conn.Query(ctx, scoresQuery, params...)

	if err != nil {
		return nil, err
	}

	return func(yield func(ScoreResult) bool) {
		defer rows.Close()
		for rows.Next() {
			score, err := scanApiScore(rows)
			result := ScoreResult{
				Score: score,
				Err:   err,
			}
			if !yield(result) {
				return
			}
		}
	}, nil
}

package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"iter"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"strconv"
	"time"
)

type ScoreResult struct {
	Score  *api.Score
	Logger slog.Logger
	Err    error
}

func (db *ScoresDB) GetScoresCount(
	ctx context.Context,
	changedSince *time.Time) (int64, error) {
	db.logger.Info("getting score count")

	query := `SELECT COUNT(*) FROM scores AS score`
	var params []any

	if changedSince != nil {
		query += " WHERE score.lastchangedat >= $1 "
		params = append(params, changedSince)
	}

	var count int64
	db.logger.Debug("Executing query", slog.String("query", query))
	err := db.conn.QueryRow(ctx, query, params...).Scan(&count)
	return count, err
}

func (db *ScoresDB) GetAllScores(
	ctx context.Context,
	skip int,
	changedSince *time.Time) (iter.Seq[ScoreResult], error) {
	db.logger.Info("getting score page")

	var rows pgx.Rows

	query := apiScoreSelect
	var params []any

	if changedSince != nil {
		query += " WHERE score.lastchangedat >= $1 "
		params = append(params, changedSince)
	}
	if skip != 0 {
		query += " SKIP " + strconv.Itoa(skip)
	}
	query = query + " ORDER BY lastChangedAt DESC "

	slog.Debug("Executing query", slog.String("query", query))
	rows, err := db.conn.Query(ctx, query, params...)

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

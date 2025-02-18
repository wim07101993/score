package database

import (
	"context"
	"github.com/jackc/pgx/v5"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"time"
)

type GetAllScoresResult struct {
	Page *api.ScoresPage
	Err  error
}

func (db *ScoresDB) GetAllScores(
	ctx context.Context,
	pageSize int32,
	changedSince *time.Time,
	pages chan<- GetAllScoresResult,
	done chan<- int) error {
	db.logger.Info("getting score page")

	const countQuery = `SELECT COUNT(*) FROM scores`
	var count int64
	err := db.conn.QueryRow(ctx, countQuery).Scan(&count)
	if err != nil {
		return err
	}

	go func() {
		var rows pgx.Rows

		if changedSince != nil {
			const scoresQuery = apiScoreSelect + `
				WHERE score.lastchangedat >= $1 
				ORDER BY lastChangedAt DESC
			`
			rows, err = db.conn.Query(ctx, scoresQuery, changedSince)
		} else {
			const scoresQuery = apiScoreSelect + `ORDER BY lastChangedAt DESC`
			rows, err = db.conn.Query(ctx, scoresQuery)
		}

		defer rows.Close()

		if err != nil {
			pages <- GetAllScoresResult{Err: err}
			return
		}
		defer close(pages)

		scores := make([]*api.Score, pageSize)
		var i int32

		for rows.Next() {
			score, err := scanApiScore(rows)
			if err != nil {
				pages <- GetAllScoresResult{Err: err}
			}

			scores[i] = score
			i++

			if i >= pageSize {
				pages <- GetAllScoresResult{Page: &api.ScoresPage{
					TotalHits: count,
					Scores:    scores,
				}}
				scores = make([]*api.Score, pageSize)
				i = 0
			}
		}

		done <- 0
	}()

	return nil
}

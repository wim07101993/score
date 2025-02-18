package database

import (
	"context"
	"score/backend/api/generated/github.com/wim07101993/score/api"
)

func (db *ScoresDB) GetScore(ctx context.Context, scoreId string) (*api.Score, error) {
	db.logger.Info("getting score")

	const query = apiScoreSelect + `WHERE score.id = $1`

	row := db.conn.QueryRow(ctx, query, scoreId)
	return scanApiScore(row)
}

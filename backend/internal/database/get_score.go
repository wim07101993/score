package database

import (
	"context"
	"log/slog"
	"score/backend/api/generated/github.com/wim07101993/score/api"
)

func (db *ScoresDb) GetScore(ctx context.Context, scoreId string) (*api.Score, error) {
	db.logger.Info("getting score")

	const query = apiScoreSelect + `WHERE score.id = $1`

	db.logger.Debug("Executing query", slog.String("query", query))
	row := db.conn.QueryRow(ctx, query, scoreId)
	return scanApiScore(row)
}

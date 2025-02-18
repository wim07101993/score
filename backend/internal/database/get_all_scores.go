package database

import (
	"context"
	"score/backend/internal/musicxml"
)

func (db *ScoresDB) GetAllScores(ctx context.Context) ([]musicxml.ScorePartwise, error) {
	db.logger.Info("getting score page")

	const query = `
		SELECT 
			score.id, 
			score.work_title,
			score.work_number,
			score.movement_number,
			score.movement_title,
			score.creators_composers,
			score.creators_lyricists,
			score.languages,
			score.instruments,
			score.lastChangedAt,
			score.tags
		FROM scores AS score
		ORDER BY lastChangedAt DESC`

	rows, err := db.conn.Query(ctx, query)
	defer rows.Close()

	if err != nil {
		return nil, err
	}

	for rows.Next() {
		// TODO
		//rows.StructScan()
	}

	//TODO
	return nil, nil
}

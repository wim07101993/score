package database

import (
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"google.golang.org/protobuf/types/known/timestamppb"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"time"
)

const apiScoreSelect = `
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
`

func scanApiScore(row pgx.Row) (*api.Score, error) {
	var (
		id                string
		workTitle         string
		workNumber        string
		movementTitle     string
		movementNumber    string
		lastChangedAt     time.Time
		creatorsComposers pgtype.Array[string]
		creatorsLyricists pgtype.Array[string]
		languages         pgtype.Array[string]
		instruments       pgtype.Array[string]
		tags              pgtype.Array[string]
	)

	err := row.Scan(
		&id,
		&workTitle,
		&workNumber,
		&movementTitle,
		&movementNumber,
		&lastChangedAt,
		&creatorsComposers,
		&creatorsLyricists,
		&languages,
		&instruments,
		&tags)

	if err != nil {
		return nil, err
	}

	return &api.Score{
		Id: id,
		Work: &api.Work{
			Title:  &workTitle,
			Number: &workNumber,
		},
		Movement: &api.Movement{
			Title:  &movementTitle,
			Number: &movementNumber,
		},
		Creators: &api.Creators{
			Composers: creatorsComposers.Elements,
			Lyricists: creatorsLyricists.Elements,
		},
		Languages:           languages.Elements,
		Instruments:         instruments.Elements,
		LastChangeTimestamp: timestamppb.New(lastChangedAt),
		Tags:                tags.Elements,
	}, nil
}

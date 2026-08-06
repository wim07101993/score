// Package score is where sheet music is kept: the documents themselves, the
// metadata read out of them when they are stored, and everything that reads or
// writes either.
//
// It knows nothing about how any of this is served. There is a file per thing
// the API asks of it, holding the queries that answer it, and what comes back
// is this package's own model of a score. Turning that into a response, and a
// failure from here into an answer for a caller, is the API layer's job — that
// is internal/server, and it is the only place that knows there is http
// involved at all.
package score

import (
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// scanScore reads a row of score metadata. Looking up a single score and
// listing a window of them select the same columns, in this order.
func scanScore(row pgx.Row) (*Score, error) {
	var (
		id                   string
		workTitle            string
		workNumber           string
		movementTitle        string
		movementNumber       string
		lastChangedAt        time.Time
		creatorsComposersArr pgtype.Array[string]
		creatorsLyricistsArr pgtype.Array[string]
		languagesArr         pgtype.Array[string]
		instrumentsArr       pgtype.Array[string]
		tagsArr              pgtype.Array[string]
	)

	err := row.Scan(
		&id,
		&workTitle,
		&workNumber,
		&movementNumber,
		&movementTitle,
		&lastChangedAt,
		&creatorsComposersArr,
		&creatorsLyricistsArr,
		&languagesArr,
		&instrumentsArr,
		&tagsArr)

	if err != nil {
		return nil, err
	}

	creatorsComposers := creatorsComposersArr.Elements
	creatorsLyricists := creatorsLyricistsArr.Elements
	languages := languagesArr.Elements
	instruments := instrumentsArr.Elements
	tags := tagsArr.Elements

	if creatorsComposers == nil {
		creatorsComposers = make([]string, 0)
	}
	if creatorsLyricists == nil {
		creatorsLyricists = make([]string, 0)
	}
	if languages == nil {
		languages = make([]string, 0)
	}
	if instruments == nil {
		instruments = make([]string, 0)
	}
	if tags == nil {
		tags = make([]string, 0)
	}

	return &Score{
		Id: id,
		Work: Work{
			Title:  workTitle,
			Number: workNumber,
		},
		Movement: Movement{
			Title:  movementTitle,
			Number: movementNumber,
		},
		Creators: Creators{
			Composers: creatorsComposers,
			Lyricists: creatorsLyricists,
		},
		Languages:     languages,
		Instruments:   instruments,
		LastChangedAt: lastChangedAt,
		Tags:          tags,
	}, nil
}

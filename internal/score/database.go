package score

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DatabaseFactory hands out a connection to the database. An operation takes
// one for as long as it is serving a request, and gives it back after.
type DatabaseFactory func(ctx context.Context) (*Database, error)

// Database is what the operations read from and write to. What each of them
// asks of it is written in its own file, next to the operation that asks.
type Database struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewDatabase(logger *slog.Logger, conn *pgxpool.Conn) *Database {
	return &Database{
		logger: logger,
		conn:   conn,
	}
}

func (db *Database) Dispose() {
	db.conn.Release()
}

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

package score

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"score/backend/internal/musicxml"
	"time"
)

type DatabaseFactory func(ctx context.Context) (*Database, error)

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

// ------------------------------------
//	MUTATING FUNCTIONS
// ------------------------------------

func (db *Database) AddOrUpdateScore(ctx context.Context, id string, score *musicxml.ScorePartwise) error {
	db.logger.Info("adding/updating score document",
		slog.String("title", score.Work.Title),
		slog.String("id", id))

	var composers []string
	var lyricists []string
	for _, creator := range score.Identification.Creators {
		switch creator.Type {
		case "composer":
			composers = append(composers, creator.Value)
		case "lyricist":
			composers = append(lyricists, creator.Value)
		}
	}

	var instruments []string
	for _, part := range score.PartList {
		if part.ScorePart == nil {
			continue
		}
		for _, instrument := range part.ScorePart.Instruments {
			if instrument.Sound == "" {
				continue
			}
			instruments = append(instruments, instrument.Sound)
		}
	}

	const insertScoreQuery = `
		INSERT INTO scores (
			id, 
			work_title, work_number, 
			movement_title, movement_number, 
			creators_composers, creators_lyricists, 
			languages, instruments, 
			lastChangedAt, tags) 
		VALUES (
			@id, 
			@work_title, @work_number, 
			@movement_title, @movement_number, 
			@creators_composers, @creators_lyricists, 
			@languages, @instruments, 
			@lastChangedAt, @tags)
		ON CONFLICT (id) DO UPDATE SET 
			work_title = EXCLUDED.work_title,
			work_number = EXCLUDED.work_number,
			movement_title = EXCLUDED.movement_title,
			movement_number = EXCLUDED.movement_number,
			creators_composers = EXCLUDED.creators_composers,
			creators_lyricists = EXCLUDED.creators_lyricists,
			languages = EXCLUDED.languages,
			instruments = EXCLUDED.instruments,
			lastChangedAt = EXCLUDED.lastChangedAt,
			tags = EXCLUDED.tags`

	_, err := db.conn.Exec(ctx, insertScoreQuery, pgx.NamedArgs{
		"id":                 id,
		"work_title":         score.Work.Title,
		"work_number":        score.Work.Number,
		"movement_title":     score.MovementTitle,
		"movement_number":    score.MovementNumber,
		"creators_composers": composers,
		"creators_lyricists": lyricists,
		"languages":          []string{score.Defaults.LyricLanguage},
		"instruments":        instruments,
		"lastChangedAt":      time.Now().UTC(),
	})
	return err
}

func (db *Database) RemoveScore(ctx context.Context, id string) error {
	db.logger.Info("removing score document", slog.String("id", id))

	const query = `
		DELETE FROM scores AS score
		WHERE score.id = $id
`
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{"id": id})
	return err
}

// ------------------------------------
//	QUERY FUNCTIONS
// ------------------------------------

func (db *Database) GetApiScore(ctx context.Context, scoreId string) (*Score, error) {
	db.logger.Info("getting score")

	row := db.conn.QueryRow(ctx, getScoreQuery, scoreId)
	return scanScore(row)
}

func (db *Database) GetScores(
	ctx context.Context,
	changesSince time.Time,
	changesUntil time.Time) ([]*Score, error) {
	db.logger.Info("getting scores")

	rows, err := db.conn.Query(ctx, getScoresQuery, changesSince, changesUntil)

	if err != nil {
		return nil, err
	}

	var scores = make([]*Score, 0)

	defer rows.Close()
	for rows.Next() {
		score, err := scanScore(rows)
		if err != nil {
			return scores, err
		}

		scores = append(scores, score)
	}

	return scores, err
}

const getScoresQuery = `
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
	WHERE score.lastchangedat >= $1 AND score.lastchangedat <= $2
	ORDER BY score.lastchangedat DESC
`

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
		&movementTitle,
		&movementNumber,
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

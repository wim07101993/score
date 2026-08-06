package score

import (
	"context"
	"encoding/xml"
	"errors"
	"log/slog"
	"strings"
	"time"

	"score/internal/musicxml"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	pkgerrors "github.com/pkg/errors"
	slogctx "github.com/veqryn/slog-context"
)

// pgErrInvalidTextRepresentation is the postgres error code for a value that
// does not parse as the type of the column it is written to, such as a uuid or
// an enum member that does not exist.
const pgErrInvalidTextRepresentation = "22P02"

// AddOrUpdate stores the document and the metadata read out of it as one:
// either both land, or neither does.
func AddOrUpdate(ctx context.Context, db *pgxpool.Conn, id string, mxml string) error {
	slogctx.Info(ctx, "adding/updating score document",
		slog.String("id", id))

	reader := strings.NewReader(mxml)
	score, err := musicxml.DeserializeMusicXml(xml.NewDecoder(reader))
	if err != nil {
		return &ErrInvalidMusicXml{Cause: err}
	}

	tx, err := db.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	_, err = tx.Exec(ctx, upsertScoreFileQuery, pgx.NamedArgs{
		"id":      id,
		"content": mxml,
	})
	if err != nil {
		return err
	}

	var composers []string
	var lyricists []string
	if score.Identification != nil && score.Identification.Creators != nil {
		for _, creator := range score.Identification.Creators {
			switch creator.Type {
			case "composer":
				composers = append(composers, creator.Value)
			case "lyricist":
				lyricists = append(lyricists, creator.Value)
			}
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

	var languages []string
	if score.Defaults != nil && score.Defaults.LyricLanguage != "" {
		languages = []string{score.Defaults.LyricLanguage}
	}

	var workTitle, workNumber string
	if score.Work != nil {
		workTitle = score.Work.Title
		workNumber = score.Work.Number
	}

	_, err = tx.Exec(ctx, upsertScoreQuery, pgx.NamedArgs{
		"id":                 id,
		"work_title":         workTitle,
		"work_number":        workNumber,
		"movement_title":     score.MovementTitle,
		"movement_number":    score.MovementNumber,
		"creators_composers": composers,
		"creators_lyricists": lyricists,
		"languages":          languages,
		"instruments":        instruments,
		"lastChangedAt":      time.Now().UTC(),
	})
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgErrInvalidTextRepresentation {
			return &ErrInvalidMusicXml{Cause: pkgerrors.New(pgErr.Message)}
		}
		return err
	}

	return tx.Commit(ctx)
}

const upsertScoreFileQuery = `
	INSERT INTO score_files (id, content)
	VALUES (@id, @content)
	ON CONFLICT (id) DO UPDATE SET
		content = EXCLUDED.content
`

const upsertScoreQuery = `
	INSERT INTO scores (
		id,
		work_title, work_number,
		movement_title, movement_number,
		creators_composers, creators_lyricists,
		languages, instruments,
		lastChangedAt)
	VALUES (
		@id,
		@work_title, @work_number,
		@movement_title, @movement_number,
		@creators_composers, @creators_lyricists,
		@languages, @instruments,
		@lastChangedAt)
	ON CONFLICT (id) DO UPDATE SET
		work_title = EXCLUDED.work_title,
		work_number = EXCLUDED.work_number,
		movement_title = EXCLUDED.movement_title,
		movement_number = EXCLUDED.movement_number,
		creators_composers = EXCLUDED.creators_composers,
		creators_lyricists = EXCLUDED.creators_lyricists,
		languages = EXCLUDED.languages,
		instruments = EXCLUDED.instruments,
		lastChangedAt = EXCLUDED.lastChangedAt
`

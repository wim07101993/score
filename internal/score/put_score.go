package score

import (
	"context"
	"encoding/xml"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"score/internal/api"
	"score/internal/httperror"
	"score/internal/musicxml"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	pkgerrors "github.com/pkg/errors"
)

// pgErrInvalidTextRepresentation is the postgres error code for a value that
// does not parse as the type of the column it is written to, such as a uuid or
// an enum member that does not exist.
const pgErrInvalidTextRepresentation = "22P02"

// PutScore stores a music-xml document and the metadata extracted from it.
func (h *Handler) PutScore(ctx context.Context, req api.PutScoreReq, params api.PutScoreParams) (api.PutScoreRes, error) {
	var document io.Reader
	switch body := req.(type) {
	case *api.PutScoreReqApplicationVndRecordareMusicxml:
		document = body.Data
	case *api.PutScoreReqApplicationVndRecordareMusicxmlXML:
		document = body.Data
	default:
		return nil, httperror.New(http.StatusUnsupportedMediaType,
			api.ProblemDetailsErrorCodeUnsupportedMediaType, "content-type not supported")
	}

	mxml, err := io.ReadAll(document)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to read request body")
	}

	db, err := h.db(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to save score")
	}
	defer db.Dispose()

	if err := db.AddOrUpdateScore(ctx, params.ScoreId.String(), string(mxml)); err != nil {
		invalidMxmlError := &ErrInvalidMusicXml{}
		if errors.As(err, &invalidMxmlError) {
			return nil, httperror.Wrap(err, http.StatusBadRequest,
				api.ProblemDetailsErrorCodeInvalidMusicXML, "invalid music xml: "+err.Error())
		}
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to save score")
	}

	return &api.PutScoreOK{}, nil
}

// ------------------------------------
//	QUERIES
// ------------------------------------

// AddOrUpdateScore stores the document and the metadata read out of it as one:
// either both land, or neither does.
func (db *Database) AddOrUpdateScore(ctx context.Context, id string, mxml string) error {
	db.logger.Info("adding/updating score document",
		slog.String("id", id))

	reader := strings.NewReader(mxml)
	score, err := musicxml.DeserializeMusicXml(xml.NewDecoder(reader))
	if err != nil {
		return &ErrInvalidMusicXml{Cause: err}
	}

	tx, err := db.conn.Begin(ctx)
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

package score

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"score/internal/api"
	"score/internal/httperror"

	"github.com/jackc/pgx/v5"
	"github.com/ogen-go/ogen/middleware"
)

// musicXmlMediaType and musicXmlXmlMediaType are the two media types a score
// document can be asked for as. They are the ones api/endpoints/scores/by_id/
// methods.yaml names for the non-json response of getScore.
const (
	musicXmlMediaType    = "application/vnd.recordare.musicxml"
	musicXmlXmlMediaType = "application/vnd.recordare.musicxml+xml"
)

// GetScore answers with the metadata of a score, or with the document that
// metadata was extracted from when that is what the Accept header asked for.
func (h *Handler) GetScore(ctx context.Context, params api.GetScoreParams) (api.GetScoreRes, error) {
	db, err := h.db(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get score")
	}
	defer db.Dispose()

	scoreId := params.ScoreId.String()

	switch acceptedMediaType(ctx) {
	case musicXmlMediaType:
		mxml, err := db.GetScoreMusicXml(ctx, scoreId)
		if err != nil {
			return nil, lookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxml{Data: strings.NewReader(mxml)}, nil

	case musicXmlXmlMediaType:
		mxml, err := db.GetScoreMusicXml(ctx, scoreId)
		if err != nil {
			return nil, lookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxmlXML{Data: strings.NewReader(mxml)}, nil

	default:
		score, err := db.GetApiScore(ctx, scoreId)
		if err != nil {
			return nil, lookupFailed(err)
		}
		return apiScore(score)
	}
}

// lookupFailed says what a failed lookup of a score means to the caller.
func lookupFailed(err error) error {
	if errors.Is(err, ErrScoreNotFound) {
		return httperror.Wrap(err, http.StatusNotFound,
			api.ProblemDetailsErrorCodeScoreNotFound, "no score found with the given id")
	}
	return httperror.Wrap(err, http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError, "failed to get score")
}

// ------------------------------------
//	CONTENT NEGOTIATION
// ------------------------------------

type contextKey int

// acceptHeaderKey is what the Accept header of the request being handled is
// kept under in the context.
const acceptHeaderKey contextKey = iota

// RememberAccept keeps the Accept header of a request within reach of the
// operation handling it.
//
// GetScore answers in the media type that was asked for, and a generated
// handler is given the parameters of a request rather than the request itself.
// It is put in front of the operations where the api server is assembled.
func RememberAccept(req middleware.Request, next middleware.Next) (middleware.Response, error) {
	req.SetContext(context.WithValue(req.Context, acceptHeaderKey, req.Raw.Header.Get("Accept")))
	return next(req)
}

// acceptedMediaType is the media type the request being handled asked for, if
// it asked for one at all.
func acceptedMediaType(ctx context.Context) string {
	accept, _ := ctx.Value(acceptHeaderKey).(string)
	return accept
}

// ------------------------------------
//	QUERIES
// ------------------------------------

func (db *Database) GetApiScore(ctx context.Context, scoreId string) (*Score, error) {
	db.logger.Info("getting score", slog.String("scoreId", scoreId))

	row := db.conn.QueryRow(ctx, getScoreQuery, scoreId)
	score, err := scanScore(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrScoreNotFound
		}
		return nil, err
	}

	return score, nil
}

func (db *Database) GetScoreMusicXml(ctx context.Context, scoreId string) (string, error) {
	db.logger.Info("getting music-xml", slog.String("scoreId", scoreId))

	row := db.conn.QueryRow(ctx, getScoreMusicXmlQuery, scoreId)

	var (
		id      string
		content string
	)

	err := row.Scan(&id, &content)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", ErrScoreNotFound
		}
		return "", err
	}

	return content, nil
}

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

const getScoreMusicXmlQuery = `
	SELECT
		score.id,
		score.content
	FROM score_files AS score
	WHERE score.id = $1
`

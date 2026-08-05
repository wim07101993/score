package score

import (
	"context"
	"net/http"
	"time"

	"score/internal/api"
	"score/internal/httperror"
)

// changeWindowLayout is how a moment is written in the Changes-Since and
// Changes-Until parameters.
const changeWindowLayout = "20060102T150405"

// ListScores answers with the metadata of every score that changed within the
// window the caller asked about.
func (h *Handler) ListScores(ctx context.Context, params api.ListScoresParams) (api.ListScoresRes, error) {
	changesSince, err := parseChangeWindowMoment(params.ChangesSince, "Changes-Since")
	if err != nil {
		return nil, err
	}
	changesUntil, err := parseChangeWindowMoment(params.ChangesUntil, "Changes-Until")
	if err != nil {
		return nil, err
	}

	db, err := h.db(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get scores page")
	}
	defer db.Dispose()

	scores, err := db.GetScores(ctx, changesSince, changesUntil)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get scores page")
	}

	page := make(api.GetScoresResponse, 0, len(scores))
	for _, score := range scores {
		apiScore, err := apiScore(score)
		if err != nil {
			return nil, err
		}
		page = append(page, *apiScore)
	}
	return &page, nil
}

// parseChangeWindowMoment reads one end of the change window. The generated
// server has already checked that it is written the way it should be; what is
// left is whether it is a moment that exists.
func parseChangeWindowMoment(moment api.ChangeWindowMoment, name string) (time.Time, error) {
	t, err := time.Parse(changeWindowLayout, string(moment))
	if err != nil {
		return time.Time{}, httperror.Wrap(err, http.StatusBadRequest,
			api.ProblemDetailsErrorCodeInvalidRequest,
			"failed to parse "+name+" as date-time (YYYYMMDDThhmmss)")
	}
	return t, nil
}

// ------------------------------------
//	QUERIES
// ------------------------------------

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

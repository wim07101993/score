package server

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"score/internal/api"
	"score/internal/httperror"
	"score/internal/score"

	"github.com/google/uuid"
)

const (
	musicXmlMediaType    = "application/vnd.recordare.musicxml"
	musicXmlXmlMediaType = "application/vnd.recordare.musicxml+xml"
)

func (h *handler) PutScore(ctx context.Context, req api.PutScoreReq, params api.PutScoreParams) (api.PutScoreRes, error) {
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
		invalidMxmlError := &score.ErrInvalidMusicXml{}
		if errors.As(err, &invalidMxmlError) {
			return nil, httperror.Wrap(err, http.StatusBadRequest,
				api.ProblemDetailsErrorCodeInvalidMusicXML, "invalid music xml: "+err.Error())
		}
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to save score")
	}

	return &api.PutScoreOK{}, nil
}

func (h *handler) GetScore(ctx context.Context, params api.GetScoreParams) (api.GetScoreRes, error) {
	db, err := h.db(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get score")
	}
	defer db.Dispose()

	scoreId := params.ScoreId.String()

	switch getAcceptHeaderFromContext(ctx) {
	case musicXmlMediaType:
		mxml, err := db.GetScoreMusicXml(ctx, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxml{Data: strings.NewReader(mxml)}, nil

	case musicXmlXmlMediaType:
		mxml, err := db.GetScoreMusicXml(ctx, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxmlXML{Data: strings.NewReader(mxml)}, nil

	default:
		stored, err := db.GetScore(ctx, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return mapScoreToApi(stored)
	}
}

func (h *handler) ListScores(ctx context.Context, params api.ListScoresParams) (api.ListScoresRes, error) {
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
	for _, stored := range scores {
		apiScore, err := mapScoreToApi(stored)
		if err != nil {
			return nil, err
		}
		page = append(page, *apiScore)
	}
	return &page, nil
}

func parseChangeWindowMoment(moment api.ChangeWindowMoment, name string) (time.Time, error) {
	t, err := time.Parse("20060102T150405", string(moment))
	if err != nil {
		return time.Time{}, httperror.Wrap(err, http.StatusBadRequest,
			api.ProblemDetailsErrorCodeInvalidRequest,
			"failed to parse "+name+" as date-time (YYYYMMDDThhmmss)")
	}
	return t, nil
}

func scoreLookupFailed(err error) error {
	if errors.Is(err, score.ErrScoreNotFound) {
		return httperror.Wrap(err, http.StatusNotFound,
			api.ProblemDetailsErrorCodeScoreNotFound, "no score found with the given id")
	}
	return httperror.Wrap(err, http.StatusInternalServerError,
		api.ProblemDetailsErrorCodeInternalError, "failed to get score")
}

func mapScoreToApi(stored *score.Score) (*api.Score, error) {
	id, err := uuid.Parse(stored.Id)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get score")
	}

	return &api.Score{
		ID: id,
		Work: api.ScoreWork{
			Title:  stored.Work.Title,
			Number: stored.Work.Number,
		},
		Movement: api.ScoreMovement{
			Title:  stored.Movement.Title,
			Number: stored.Movement.Number,
		},
		Creators: api.ScoreCreators{
			Composers: stored.Creators.Composers,
			Lyricists: stored.Creators.Lyricists,
		},
		Languages:     stored.Languages,
		Instruments:   stored.Instruments,
		LastChangedAt: stored.LastChangedAt,
		Tags:          stored.Tags,
	}, nil
}

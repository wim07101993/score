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

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to save score")
	}
	defer dbConn.Release()

	if err := score.AddOrUpdate(ctx, dbConn, params.ScoreId.String(), string(mxml)); err != nil {
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

func (h *Handler) GetScore(ctx context.Context, params api.GetScoreParams) (api.GetScoreRes, error) {
	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get score")
	}
	defer dbConn.Release()

	scoreId := params.ScoreId.String()

	switch getAcceptHeaderFromContext(ctx) {
	case musicXmlMediaType:
		mxml, err := score.GetMusicXml(ctx, dbConn, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxml{Data: strings.NewReader(mxml)}, nil

	case musicXmlXmlMediaType:
		mxml, err := score.GetMusicXml(ctx, dbConn, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return &api.GetScoreOKApplicationVndRecordareMusicxmlXML{Data: strings.NewReader(mxml)}, nil

	default:
		stored, err := score.Get(ctx, dbConn, scoreId)
		if err != nil {
			return nil, scoreLookupFailed(err)
		}
		return mapScoreToApi(stored)
	}
}

func (h *Handler) ListScores(ctx context.Context, params api.ListScoresParams) (api.ListScoresRes, error) {
	changesSince, err := parseChangeWindowMoment(params.ChangesSince, "Changes-Since")
	if err != nil {
		return nil, err
	}
	changesUntil, err := parseChangeWindowMoment(params.ChangesUntil, "Changes-Until")
	if err != nil {
		return nil, err
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, httperror.Wrap(err, http.StatusInternalServerError,
			api.ProblemDetailsErrorCodeInternalError, "failed to get scores page")
	}
	defer dbConn.Release()

	scores, err := score.List(ctx, dbConn, changesSince, changesUntil)
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

package server

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"score/internal/api"
	"score/internal/failure"
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
		return nil, api.NewProblemDetails(http.StatusUnsupportedMediaType,
			api.ProblemDetailsErrorCodeUnsupportedMediaType, "content-type not supported")
	}

	mxml, err := io.ReadAll(document)
	if err != nil {
		return nil, failure.Internal("failed to read request body", err)
	}

	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, failure.Internal("failed to save score", err)
	}
	defer dbConn.Release()

	if err := score.AddOrUpdate(ctx, dbConn, params.ScoreId.String(), string(mxml)); err != nil {
		invalidMxmlError := &score.ErrInvalidMusicXml{}
		if errors.As(err, &invalidMxmlError) {
			return nil, api.NewProblemDetails(http.StatusBadRequest,
				api.ProblemDetailsErrorCodeInvalidMusicXML, "invalid music xml: "+err.Error())
		}
		return nil, failure.Internal("failed to save score", err)
	}

	return &api.PutScoreOK{}, nil
}

func (h *Handler) GetScore(ctx context.Context, params api.GetScoreParams) (api.GetScoreRes, error) {
	dbConn, err := h.db.Provide(ctx)
	if err != nil {
		return nil, failure.Internal("failed to get score", err)
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
		return nil, failure.Internal("failed to get scores page", err)
	}
	defer dbConn.Release()

	scores, err := score.List(ctx, dbConn, changesSince, changesUntil)
	if err != nil {
		return nil, failure.Internal("failed to get scores page", err)
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
		return time.Time{}, api.NewProblemDetails(http.StatusBadRequest,
			api.ProblemDetailsErrorCodeInvalidRequest,
			"failed to parse "+name+" as date-time (YYYYMMDDThhmmss)")
	}
	return t, nil
}

func scoreLookupFailed(err error) error {
	if errors.Is(err, score.ErrScoreNotFound) {
		return api.NewProblemDetails(http.StatusNotFound,
			api.ProblemDetailsErrorCodeScoreNotFound, "no score found with the given id")
	}
	return failure.Internal("failed to get score", err)
}

func mapScoreToApi(stored *score.Score) (*api.Score, error) {
	id, err := uuid.Parse(stored.Id)
	if err != nil {
		return nil, failure.Internal("failed to get score", err)
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

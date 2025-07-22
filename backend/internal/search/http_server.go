package search

import (
	"encoding/json"
	"errors"
	"log/slog"
	"math"
	"net/http"
	"score/backend/api/generated/github.com/wim07101993/score/api"
	"score/backend/internal/database"
	"strconv"
	"time"
)

type SearcherHttpServer struct {
	logger *slog.Logger
	db     database.ScoresDbFactory
}

func NewSearcherHttpServer(logger *slog.Logger, db database.ScoresDbFactory) *SearcherHttpServer {
	return &SearcherHttpServer{
		logger: logger,
		db:     db,
	}
}

func (serv *SearcherHttpServer) RegisterRoutes() {
	http.HandleFunc("/scores/{scoreId}", func(res http.ResponseWriter, req *http.Request) {
		switch req.Method {
		case http.MethodGet:
			serv.GetScore(res, req)
		default:
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
	})
	http.HandleFunc("/scores", func(res http.ResponseWriter, req *http.Request) {
		switch req.Method {
		case http.MethodGet:
			serv.GetScoresPage(res, req)
		default:
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
	})
}

func (serv *SearcherHttpServer) GetScore(res http.ResponseWriter, req *http.Request) {
	scoreId := req.PathValue("scoreId")
	if scoreId == "" {
		http.NotFound(res, req)
		return
	}

	db, err := serv.db(req.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return
	}
	defer db.ReleaseConnection()

	score, err := db.GetScore(req.Context(), scoreId)
	if err != nil {
		serv.logger.Error("failed to lookup score", slog.Any("error", err))
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return
	}
	if score == nil {
		http.NotFound(res, req)
		return
	}

	bs, err := json.Marshal(score)
	if err != nil {
		serv.logger.Error("failed to serialize score", slog.Any("error", err))
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return
	}

	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		serv.logger.Error("respond score", slog.Any("error", err))
		return
	}
}

func (serv *SearcherHttpServer) GetScoresPage(res http.ResponseWriter, req *http.Request) {
	db, err := serv.db(req.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}
	defer db.ReleaseConnection()

	pageIndex, err := getPageIndex(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return
	}
	pageSize, err := getPageSize(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return
	}
	changedSince, err := getChangedSince(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return
	}

	count, err := db.GetScoresCount(req.Context(), changedSince)
	if err != nil {
		serv.logger.Error("failed to get count of all scores", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}

	results, err := db.GetAllScores(req.Context(), pageIndex*pageSize, changedSince)

	if err != nil {
		serv.logger.Error("failed to query all scores", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}

	scores := make([]*api.Score, pageSize)
	var i int
	for result := range results {
		if result.Err != nil {
			serv.logger.Error("failed to query scores page", slog.Any("error", result.Err))
			http.Error(res, "failed to get scores page", http.StatusInternalServerError)
			return
		}

		scores[i] = result.Score
		i++
		if i == math.MaxInt || i >= pageSize {
			break
		}
	}

	bs, err := json.Marshal(&api.ScoresPage{
		TotalHits: count,
		Scores:    scores,
	})
	if err != nil {
		serv.logger.Error("failed to serialize scores page", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}

	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		serv.logger.Error("respond scores page", slog.Any("error", err))
		return
	}
}

func getPageIndex(req *http.Request) (int, error) {
	s := req.URL.Query().Get("Page-Index")
	if s == "" {
		return 0, nil
	}

	i, err := strconv.Atoi(s)
	if err != nil {
		return 0, errors.New("could not parse Page-Index as an integer")
	}
	if i < 0 {
		return 0, errors.New("Page-Index must be greater than or equal to 0")
	}
	return i, nil
}

func getPageSize(req *http.Request) (int, error) {
	s := req.URL.Query().Get("Page-Size")
	if s == "" {
		return 10, nil
	}

	i, err := strconv.Atoi(s)
	if err != nil {
		return 0, errors.New("failed to parse Page-Size as an integer")
	}
	if i < 1 {
		return 0, errors.New("Page-Size must be greater than or equal to 1")
	}
	if i > 100 {
		return 0, errors.New("Page-Size must be less than or equal to 100")
	}
	return i, nil
}

func getChangedSince(req *http.Request) (*time.Time, error) {
	s := req.URL.Query().Get("Changed-Since")
	if s == "" {
		return nil, nil
	}

	t, err := time.Parse("2006-01-02T15:04:05-0700", s)
	if err != nil {
		return nil, errors.New("failed to parse Changed-Since as date-time (ISO8601)")
	}
	if t.Nanosecond() == 0 {
		return nil, nil
	}
	return &t, nil
}

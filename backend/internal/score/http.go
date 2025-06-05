package score

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"
)

type HttpServer struct {
	logger *slog.Logger
	db     DatabaseFactory
}

func NewHttpServer(logger *slog.Logger, db DatabaseFactory) *HttpServer {
	return &HttpServer{
		logger: logger,
		db:     db,
	}
}

func (serv *HttpServer) RegisterRoutes() {
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

func (serv *HttpServer) GetScore(res http.ResponseWriter, req *http.Request) {
	// VALIDATE INPUT
	scoreId := req.PathValue("scoreId")
	if scoreId == "" {
		http.NotFound(res, req)
		return
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return
	}

	score, err := db.GetApiScore(req.Context(), scoreId)
	if err != nil {
		serv.logger.Error("failed to lookup score", slog.Any("error", err))
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return
	}

	// RETURN RESULT
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

func (serv *HttpServer) GetScoresPage(res http.ResponseWriter, req *http.Request) {
	// VALIDATE INPUT
	changesSince, err := getChangesSinceParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return
	}
	changesUntil, err := getChangesUntilParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		serv.logger.Error("failed to connect to the database", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}

	scores, err := db.GetScores(req.Context(), changesSince, changesUntil)

	if err != nil {
		serv.logger.Error("failed to query all scores", slog.Any("error", err))
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return
	}

	// RETURN RESULT

	bs, err := json.Marshal(scores)
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

func getChangesSinceParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Since")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Since query param must be provided")
	}

	t, err := time.Parse("2006-01-02T15:04:05-0700", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Since as date-time (ISO8601)")
	}
	if t.Nanosecond() == 0 {
		return time.Time{}, errors.New("a Changes-Since query param must be provided")
	}
	return t, nil
}

func getChangesUntilParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Until")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Until query param must be provided")
	}

	t, err := time.Parse("2006-01-02T15:04:05-0700", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Until as date-time (ISO8601)")
	}
	if t.Nanosecond() == 0 {
		return time.Time{}, errors.New("a Changes-Until query param must be provided")
	}
	return t, nil
}

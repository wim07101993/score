package score

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"score/backend/internal/auth"
	"score/backend/internal/logging"
	"time"
)

const scoreIdQueryParam = "scoreId"

type HttpServer struct {
	logger         *slog.Logger
	db             DatabaseFactory
	authMiddleware *auth.Middleware
}

func NewHttpServer(logger *slog.Logger, db DatabaseFactory, auth *auth.Middleware) *HttpServer {
	return &HttpServer{
		logger:         logger,
		db:             db,
		authMiddleware: auth,
	}
}

func (serv *HttpServer) RegisterRoutes() {
	serv.handleFunc("/scores/{scoreId}",
		serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
			switch req.Method {
			case http.MethodGet:
				accepts := req.Header.Get("Accept")
				if accepts == "application/vnd.recordare.musicxml" ||
					accepts == "application/vnd.recordare.musicxml+xml" {
					return serv.GetScoreMusicxml(res, req)
				}
				return serv.GetScoreMetadata(res, req)
			case http.MethodPut:
				return serv.PutScore(res, req)
			default:
				http.Error(res, "", http.StatusMethodNotAllowed)
				return nil
			}
		}))
	serv.handleFunc("/scores", serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
		switch req.Method {
		case http.MethodGet:
			return serv.GetScoresPage(res, req)
		default:
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
		return nil
	}))
	serv.handleFunc("/healthz", func(res http.ResponseWriter, req *http.Request) error {
		res.WriteHeader(200)
		_, _ = res.Write([]byte("OK"))
		return nil
	})
	serv.handleFunc("/", func(res http.ResponseWriter, req *http.Request) error {
		http.NotFound(res, req)
		return nil
	})
}

func (serv *HttpServer) handleFunc(pattern string, handler func(http.ResponseWriter, *http.Request) error) {
	http.HandleFunc(pattern, cors(
		logging.Wrap(serv.logger, func(res http.ResponseWriter, req *http.Request) error {
			return handler(res, req)
		})))
}

func (serv *HttpServer) GetScoreMetadata(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId := req.PathValue(scoreIdQueryParam)
	if scoreId == "" {
		http.NotFound(res, req)
		return nil
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	score, err := db.GetApiScore(req.Context(), scoreId)
	if err != nil {
		if errors.Is(err, ErrScoreNotFound) {
			http.Error(res, "no score found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return fmt.Errorf("failed to lookup score: %v", err)
	}

	// RETURN RESULT
	bs, err := json.Marshal(score)
	if err != nil {
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return fmt.Errorf("failed to serialize score: %v", err)
	}

	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		return fmt.Errorf("failed to respond score: %v", err)
	}

	return nil
}

func (serv *HttpServer) GetScoreMusicxml(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId := req.PathValue(scoreIdQueryParam)
	if scoreId == "" {
		http.NotFound(res, req)
		return nil
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	mxml, err := db.GetScoreMusicXml(req.Context(), scoreId)
	if err != nil {
		if errors.Is(err, ErrScoreNotFound) {
			http.Error(res, "no score found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to get score", http.StatusInternalServerError)
		return fmt.Errorf("failed to lookup score: %v", err)
	}

	res.WriteHeader(http.StatusOK)
	res.Header().Set("Content-Type", "application/vnd.recordare.musicxml")
	if _, err = res.Write([]byte(mxml)); err != nil {
		return fmt.Errorf("failed to respond score: %v", err)
	}
	return nil
}

func (serv *HttpServer) PutScore(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId := req.PathValue(scoreIdQueryParam)
	if scoreId == "" {
		http.NotFound(res, req)
		return errors.New("no score-id")
	}

	contentType := req.Header.Get("Content-Type")
	if contentType != "application/vnd.recordare.musicxml" &&
		contentType != "application/vnd.recordare.musicxml+xml" {
		http.Error(res, "content-type not supported", http.StatusUnsupportedMediaType)
		return errors.New("content-type not supported")
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to save score", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	mxml, err := io.ReadAll(req.Body)
	if err != nil {
		http.Error(res, "failed to read request body", http.StatusInternalServerError)
		return fmt.Errorf("failed to read request body: %v", err)
	}

	err = db.AddOrUpdateScore(req.Context(), scoreId, string(mxml))
	if err != nil {
		invalidMxmlError := &ErrInvalidMusicXml{}
		if errors.As(err, &invalidMxmlError) {
			http.Error(res, fmt.Sprintf("invalid music xml: %s", err), http.StatusBadRequest)
			return fmt.Errorf("invalid music xml: %s", err)
		}

		http.Error(res, "failed to save score", http.StatusInternalServerError)
		return fmt.Errorf("failed to save score to the database: %v", err)
	}

	// RETURN RESULT
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) GetScoresPage(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	changesSince, err := getChangesSinceParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}
	changesUntil, err := getChangesUntilParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	scores, err := db.GetScores(req.Context(), changesSince, changesUntil)

	if err != nil {
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return fmt.Errorf("failed to query all scores: %v", err)
	}

	// RETURN RESULT

	bs, err := json.Marshal(scores)
	if err != nil {
		http.Error(res, "failed to get scores page", http.StatusInternalServerError)
		return fmt.Errorf("failed to serialize scores page: %v", err)
	}

	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		return fmt.Errorf("failed respond scores page: %v", err)
	}

	return nil
}

func getChangesSinceParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Since")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Since query param must be provided")
	}

	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Since as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Since query param cannot be empty")
	}
	return t, nil
}

func getChangesUntilParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Until")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Until query param must be provided")
	}

	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Until as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Until query param cannot be empty")
	}
	return t, nil
}

func cors(handler http.HandlerFunc) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Access-Control-Allow-Origin", "*")
		res.Header().Set("Access-Control-Allow-Headers", "*")
		if req.Method == http.MethodOptions {
			_, _ = res.Write([]byte("OK"))
			return
		}
		handler(res, req)
	}
}

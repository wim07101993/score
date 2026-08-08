package score

import (
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"score/internal/auth"
	"score/internal/http_helpers"
	"score/internal/logging"

	"github.com/google/uuid"
)

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

func (serv *HttpServer) RegisterRoutes(mux *http.ServeMux) {
	serv.handleFunc(mux, "/scores/{scoreId}",
		serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
			switch req.Method {
			case http.MethodGet:
				accepts := req.Header.Get("Accept")
				if accepts == "application/vnd.recordare.musicxml" ||
					accepts == "application/vnd.recordare.musicxml+xml" {
					return serv.authMiddleware.RequireRole(auth.RoleScoreViewer, serv.GetScoreMusicxml)(res, req)
				}
				return serv.authMiddleware.RequireRole(auth.RoleScoreViewer, serv.GetScoreMetadata)(res, req)
			case http.MethodPut:
				return serv.authMiddleware.RequireRole(auth.RoleScoreEditor, serv.PutScore)(res, req)
			default:
				http.Error(res, "", http.StatusMethodNotAllowed)
				return nil
			}
		}))
	serv.handleFunc(mux, "/scores", serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
		switch req.Method {
		case http.MethodGet:
			return serv.authMiddleware.RequireRole(auth.RoleScoreViewer, serv.GetScoresPage)(res, req)
		default:
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
		return nil
	}))
	serv.handleFunc(mux, "/healthz", func(res http.ResponseWriter, req *http.Request) error {
		res.WriteHeader(200)
		_, _ = res.Write([]byte("OK"))
		return nil
	})
	serv.handleFunc(mux, "/", func(res http.ResponseWriter, req *http.Request) error {
		http.NotFound(res, req)
		return nil
	})
}

func (serv *HttpServer) handleFunc(mux *http.ServeMux, pattern string, handler func(http.ResponseWriter, *http.Request) error) {
	mux.HandleFunc(pattern, http_helpers.Cors(
		logging.Wrap(serv.logger, func(res http.ResponseWriter, req *http.Request) error {
			return handler(res, req)
		})))
}

func (serv *HttpServer) GetScoreMetadata(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId, err := getScoreIdFromPath(res, req)
	if err != nil {
		return err
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
	return http_helpers.RespondJson(res, score)
}

func (serv *HttpServer) GetScoreMusicxml(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId, err := getScoreIdFromPath(res, req)
	if err != nil {
		return err
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

	res.Header().Set("Content-Type", "application/vnd.recordare.musicxml")
	res.WriteHeader(http.StatusOK)
	if _, err = res.Write([]byte(mxml)); err != nil {
		return fmt.Errorf("failed to respond score: %v", err)
	}
	return nil
}

func (serv *HttpServer) PutScore(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	scoreId, err := getScoreIdFromPath(res, req)
	if err != nil {
		return err
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
	changesSince, err := http_helpers.GetChangesSinceParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}
	changesUntil, err := http_helpers.GetChangesUntilParam(req)
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

	return http_helpers.RespondJson(res, scores)
}

func getScoreIdFromPath(res http.ResponseWriter, req *http.Request) (string, error) {
	id := req.PathValue("scoreId")
	if id == "" {
		http.NotFound(res, req)
		return "", errors.New("no score-id")
	}
	if _, err := uuid.Parse(id); err != nil {
		http.Error(res, "the score id is not a valid uuid", http.StatusBadRequest)
		return "", fmt.Errorf("malformed score-id %q: %v", id, err)
	}
	return id, nil
}

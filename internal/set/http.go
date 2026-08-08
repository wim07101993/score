package set

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"score/internal/auth"
	"score/internal/http_helpers"
	"score/internal/logging"

	"github.com/google/uuid"
)

const setIdPathValue = "setId"

type HttpServer struct {
	logger         *slog.Logger
	db             DatabaseFactory
	authMiddleware *auth.Middleware
}

func NewHttpServer(logger *slog.Logger, db DatabaseFactory, authMiddleware *auth.Middleware) *HttpServer {
	return &HttpServer{
		logger:         logger,
		db:             db,
		authMiddleware: authMiddleware,
	}
}

// RegisterRoutes adds the set routes to mux.
//
// A set is personal: it names scores but changes nothing about them, so
// building one asks no more of a user than reading the scores in it.
func (serv *HttpServer) RegisterRoutes(mux *http.ServeMux) {
	serv.handleFunc(mux, "/sets/{setId}",
		serv.authMiddleware.Authenticate(
			serv.authMiddleware.RequireRole(auth.RoleScoreViewer,
				func(res http.ResponseWriter, req *http.Request) error {
					switch req.Method {
					case http.MethodGet:
						return serv.GetSet(res, req)
					case http.MethodPut:
						return serv.PutSet(res, req)
					case http.MethodDelete:
						return serv.DeleteSet(res, req)
					default:
						http.Error(res, "", http.StatusMethodNotAllowed)
						return nil
					}
				})))

	serv.handleFunc(mux, "/sets",
		serv.authMiddleware.Authenticate(
			serv.authMiddleware.RequireRole(auth.RoleScoreViewer,
				func(res http.ResponseWriter, req *http.Request) error {
					switch req.Method {
					case http.MethodGet:
						return serv.GetSetsPage(res, req)
					default:
						http.Error(res, "", http.StatusMethodNotAllowed)
						return nil
					}
				})))
}

func (serv *HttpServer) handleFunc(mux *http.ServeMux, pattern string, handler func(http.ResponseWriter, *http.Request) error) {
	mux.HandleFunc(pattern, http_helpers.Cors(
		logging.Wrap(serv.logger, func(res http.ResponseWriter, req *http.Request) error {
			return handler(res, req)
		})))
}

func (serv *HttpServer) GetSet(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	setId, err := getSetIdFromPath(res, req)
	if err != nil {
		return err
	}
	user, err := http_helpers.UserOfRequest(res, req)
	if err != nil {
		return err
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get set", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	found, err := db.GetSet(req.Context(), setId, user)
	if err != nil {
		if errors.Is(err, ErrSetNotFound) {
			http.Error(res, "no set found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to get set", http.StatusInternalServerError)
		return fmt.Errorf("failed to lookup set: %v", err)
	}

	// RETURN RESULT
	return http_helpers.RespondJson(res, found)
}

func (serv *HttpServer) GetSetsPage(res http.ResponseWriter, req *http.Request) error {
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
	user, err := http_helpers.UserOfRequest(res, req)
	if err != nil {
		return err
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get sets page", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	sets, err := db.GetSets(req.Context(), user, changesSince, changesUntil)
	if err != nil {
		http.Error(res, "failed to get sets page", http.StatusInternalServerError)
		return fmt.Errorf("failed to query sets: %v", err)
	}

	// RETURN RESULT
	return http_helpers.RespondJson(res, sets)
}

func (serv *HttpServer) PutSet(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	setId, err := getSetIdFromPath(res, req)
	if err != nil {
		return err
	}
	user, err := http_helpers.UserOfRequest(res, req)
	if err != nil {
		return err
	}

	var write WriteSet
	if err := json.NewDecoder(req.Body).Decode(&write); err != nil {
		http.Error(res, "the body is not a set", http.StatusBadRequest)
		return fmt.Errorf("failed to parse the set: %v", err)
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to save set", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	if err := db.SaveSet(req.Context(), setId, user, write); err != nil {
		return serv.respondSaveError(res, err)
	}

	// RETURN RESULT
	saved, err := db.GetSet(req.Context(), setId, user)
	if err != nil {
		http.Error(res, "failed to save set", http.StatusInternalServerError)
		return fmt.Errorf("failed to read back the saved set: %v", err)
	}
	return http_helpers.RespondJson(res, saved)
}

func (serv *HttpServer) DeleteSet(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	setId, err := getSetIdFromPath(res, req)
	if err != nil {
		return err
	}
	user, err := http_helpers.UserOfRequest(res, req)
	if err != nil {
		return err
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to delete set", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	if err := db.DeleteSet(req.Context(), setId, user); err != nil {
		if errors.Is(err, ErrSetNotFound) {
			http.Error(res, "no set found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to delete set", http.StatusInternalServerError)
		return fmt.Errorf("failed to delete set: %v", err)
	}

	// RETURN RESULT
	res.WriteHeader(http.StatusNoContent)
	return nil
}

// respondSaveError turns the ways a set can be refused into the answers they
// deserve: what the caller sent, what is not theirs, and what went wrong here.
func (serv *HttpServer) respondSaveError(res http.ResponseWriter, err error) error {
	invalid := &ErrInvalidSet{}
	if errors.As(err, &invalid) {
		http.Error(res, invalid.Error(), http.StatusBadRequest)
		return err
	}

	unknownScore := &ErrUnknownScore{}
	if errors.As(err, &unknownScore) {
		http.Error(res, unknownScore.Error(), http.StatusBadRequest)
		return err
	}

	if errors.Is(err, ErrNotSetOwner) {
		http.Error(res, "only the owner of a set can change it", http.StatusForbidden)
		return err
	}

	http.Error(res, "failed to save set", http.StatusInternalServerError)
	return fmt.Errorf("failed to save set: %v", err)
}

// ------------------------------------
//	HELPERS
// ------------------------------------

func getSetIdFromPath(res http.ResponseWriter, req *http.Request) (string, error) {
	id := req.PathValue(setIdPathValue)
	if id == "" {
		http.NotFound(res, req)
		return "", errors.New("no set-id")
	}
	if _, err := uuid.Parse(id); err != nil {
		http.Error(res, "the set id is not a valid uuid", http.StatusBadRequest)
		return "", fmt.Errorf("malformed set-id %q: %v", id, err)
	}
	return id, nil
}

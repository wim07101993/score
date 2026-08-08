package http_helpers

import (
	"errors"
	"net/http"
	"score/internal"
	"score/internal/auth"
	"time"
)

func UserOfRequest(res http.ResponseWriter, req *http.Request) (*auth.UserInfo, error) {
	user, ok := req.Context().Value(internal.UserInfoKey).(*auth.UserInfo)
	if !ok {
		http.Error(res, "no user info", http.StatusUnauthorized)
		return nil, errors.New("no user info on an authenticated request")
	}
	return user, nil
}

func GetChangesSinceParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Since")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Since query param must be provided")
	}

	t, err := time.Parse("20260102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Since as date-time (YYMMDDThhmmss)")
	}
	return t, nil
}

func GetChangesUntilParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Until")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Until query param must be provided")
	}

	t, err := time.Parse("20260102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Until as date-time (YYMMDDThhmmss)")
	}
	return t, nil
}

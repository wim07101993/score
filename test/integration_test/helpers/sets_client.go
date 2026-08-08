package helpers

import (
	"encoding/json"
	"net/http"
	"net/url"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// Set mirrors the JSON contract of the sets API, so a change to the wire format
// shows up as a test failure rather than as a surprise in the frontend.
type Set struct {
	Id            string     `json:"id"`
	Title         string     `json:"title"`
	Description   string     `json:"description"`
	Entries       []SetEntry `json:"entries"`
	SharedWith    []string   `json:"shared_with"`
	IsOwner       bool       `json:"is_owner"`
	LastChangedAt time.Time  `json:"last_changed_at"`
	DeletedAt     *time.Time `json:"deleted_at"`
}

type SetEntry struct {
	Id            string   `json:"id"`
	ScoreId       string   `json:"score_id"`
	Description   string   `json:"description"`
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
}

// WriteSet is what a client sends to create or replace a set.
type WriteSet struct {
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Entries     []SetEntry `json:"entries"`
	SharedWith  []string   `json:"shared_with"`
}

// ScoreIds is the running order of a set, which is the thing most tests about
// ordering want to assert on.
func (s Set) ScoreIds() []string {
	ids := make([]string, 0, len(s.Entries))
	for _, entry := range s.Entries {
		ids = append(ids, entry.ScoreId)
	}
	return ids
}

func (r Response) DecodeSet(t *testing.T) Set {
	t.Helper()

	var s Set
	require.NoErrorf(t, json.Unmarshal(r.Body, &s), "failed to parse set response: %s", r.Text())
	return s
}

func (r Response) DecodeSets(t *testing.T) []Set {
	t.Helper()

	var sets []Set
	require.NoErrorf(t, json.Unmarshal(r.Body, &sets), "failed to parse sets response: %s", r.Text())
	return sets
}

// PutSet creates or replaces a set.
func (c *ScoresClient) PutSet(t *testing.T, setId string, token string, write WriteSet) Response {
	t.Helper()

	body, err := json.Marshal(write)
	require.NoError(t, err, "failed to build the set body")

	return c.Do(t, Request{
		Method:      http.MethodPut,
		Path:        "/sets/" + setId,
		Token:       token,
		ContentType: "application/json",
		Body:        string(body),
	})
}

// MustPutSet saves a set and fails the test unless the API accepted it.
func (c *ScoresClient) MustPutSet(t *testing.T, setId string, token string, write WriteSet) Set {
	t.Helper()

	res := c.PutSet(t, setId, token, write)
	require.Equalf(t, http.StatusOK, res.StatusCode, "failed to save set %s: %s", setId, res.Text())
	return res.DecodeSet(t)
}

func (c *ScoresClient) GetSet(t *testing.T, setId string, token string) Response {
	t.Helper()

	return c.Do(t, Request{
		Method: http.MethodGet,
		Path:   "/sets/" + setId,
		Token:  token,
		Accept: "application/json",
	})
}

func (c *ScoresClient) DeleteSet(t *testing.T, setId string, token string) Response {
	t.Helper()

	return c.Do(t, Request{
		Method: http.MethodDelete,
		Path:   "/sets/" + setId,
		Token:  token,
	})
}

// ListSets fetches every set the caller may see that changed within the window.
func (c *ScoresClient) ListSets(t *testing.T, token string, since time.Time, until time.Time) Response {
	t.Helper()

	query := url.Values{}
	query.Set("Changes-Since", since.UTC().Format(changeWindowLayout))
	query.Set("Changes-Until", until.UTC().Format(changeWindowLayout))

	return c.Do(t, Request{
		Method: http.MethodGet,
		Path:   "/sets?" + query.Encode(),
		Token:  token,
		Accept: "application/json",
	})
}

// FindSet picks a set out of a list response by id, reporting whether it is
// there at all.
func FindSet(sets []Set, setId string) (Set, bool) {
	for _, s := range sets {
		if s.Id == setId {
			return s, true
		}
	}
	return Set{}, false
}

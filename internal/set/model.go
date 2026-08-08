// Package set holds the sets a user plays a gig from: an ordered list of
// scores, each with the key it is played in and the parts that are on screen.
//
// A set says how a score is played, never what it is. Nothing here writes to a
// score, and two sets can play the same score in different keys without either
// of them changing it.
package set

import "time"

// MinTransposition and MaxTransposition bound how far an entry may be
// transposed, matching what the player offers.
const (
	MinTransposition = -12
	MaxTransposition = 12
)

// Set is a playlist for a gig.
type Set struct {
	Id          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`

	// Entries are in playing order.
	Entries []Entry `json:"entries"`

	// SharedWith holds the addresses the set is readable by. It is only filled
	// in for the owner: who else someone shares with is not the business of the
	// people they share with.
	SharedWith []string `json:"shared_with"`

	// IsOwner tells the caller whether this set is theirs to change.
	IsOwner bool `json:"is_owner"`

	LastChangedAt time.Time `json:"last_changed_at"`

	// DeletedAt marks a set that has been deleted. It is still returned by the
	// change window so that a client which has the set cached knows to drop it.
	DeletedAt *time.Time `json:"deleted_at"`
}

// Entry is one score as it is played at one point in a gig.
type Entry struct {
	// Id belongs to the entry rather than to the score, because the same score
	// may be played more than once in a gig.
	Id      string `json:"id"`
	ScoreId string `json:"score_id"`

	// Description is whatever the player needs to remember about this one:
	// "capo 2", "second verse only", "straight into the next".
	Description string `json:"description"`

	// Transposition is in semitones, negative for down.
	Transposition int `json:"transposition"`

	// HiddenParts names the parts of the score that are off screen, by their
	// MusicXML part id.
	HiddenParts []string `json:"hidden_parts"`
}

// WriteSet is what a client sends to create or replace a set. It is a separate
// type from Set because most of what the API returns is not the client's to
// state: who owns a set, when it last changed and whether it is deleted are
// decided here.
type WriteSet struct {
	Title       string       `json:"title"`
	Description string       `json:"description"`
	Entries     []WriteEntry `json:"entries"`
	SharedWith  []string     `json:"shared_with"`
}

type WriteEntry struct {
	Id            string   `json:"id"`
	ScoreId       string   `json:"score_id"`
	Description   string   `json:"description"`
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
}

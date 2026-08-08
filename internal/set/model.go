package set

import "time"

const (
	MinTransposition = -12
	MaxTransposition = 12
)

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

	LastChangedAt time.Time  `json:"last_changed_at"`
	DeletedAt     *time.Time `json:"deleted_at"`
}

// Entry is one score as it is played at one point in a gig. Its Id is minted
// here when the set is written, not stated by whoever wrote it.
type Entry struct {
	Id            string   `json:"id"`
	ScoreId       string   `json:"score_id"`
	Description   string   `json:"description"`
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
}

type WriteSet struct {
	Title       string       `json:"title"`
	Description string       `json:"description"`
	Entries     []WriteEntry `json:"entries"`
	SharedWith  []string     `json:"shared_with"`
}

// WriteEntry is an entry as the client states it: everything about how a score
// is played, and nothing about which row it is kept as. Entries are replaced
// whole on every write, so each one is stored under a fresh id.
type WriteEntry struct {
	ScoreId       string   `json:"score_id"`
	Description   string   `json:"description"`
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
}

package set

import "time"

const (
	MinTransposition = -12
	MaxTransposition = 12
)

const (
	MinZoom     float64 = 0.5
	MaxZoom     float64 = 4
	DefaultZoom float64 = 1
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

// Entry is one score as it is played at one point in a gig.
//
// Everything here but View is the same for everyone the set is shared with: it
// is what the band does, and it is the owner's to say. View is the caller's own
// and nobody else's.
type Entry struct {
	Id string `json:"id"`

	// ScoreId is the score that is played, and nil for a song that has none.
	ScoreId *string `json:"score_id"`

	Description string `json:"description"`

	// Position is where in the running order this one is played, counting from
	// zero. The entries of a set come back in playing order, so it says nothing
	// the order does not; it is here for a client holding one entry on its own.
	Position int `json:"position"`

	// Transposition is how far the band plays this one from where it is
	// written. It is the arrangement rather than anyone's reading of it.
	Transposition int `json:"transposition"`

	// View is how the caller looks at this entry, which is theirs alone.
	View EntryView `json:"view"`
}

// EntryView is how one player looks at one entry.
//
// A set says what the band plays; a view says what one player looks at while
// they play it. Playing a song a tone down is the band's decision and reading
// it in another key because of the instrument it is played on is the player's,
// so they are two things rather than one: a saxophone player transposing their
// part changes nothing for the pianist, and the pianist wanting the piano staff
// alone on screen changes nothing for the singer.
//
// An entry a player has never looked at differently has the zero value, which
// is the view every entry starts with: as written, every part on screen.
type EntryView struct {
	// Transposition is on top of the entry's rather than instead of it.
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
	Zoom          float64  `json:"zoom"`
}

// WriteSet is what a set is, as the client states it: the gig, and who may read
// it. What is played in it is not here — an entry is a resource of its own, so
// a set is created empty and filled afterwards.
type WriteSet struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	SharedWith  []string `json:"shared_with"`
}

// WriteEntry is one entry as the owner of the set states it: what the band does
// with one score, and nothing about how anybody looks at it. A view belongs to
// a player rather than to a set, so writing an entry leaves every player's view
// of it alone, the owner's own included.
//
// Which entry it is, is not here either: it is named by whoever writes it, in
// the path.
type WriteEntry struct {
	// ScoreId is the score that is played, and nil for a song that is on paper
	// rather than in here.
	ScoreId       *string `json:"score_id"`
	Description   string  `json:"description"`
	Transposition int     `json:"transposition"`

	// Position is where in the running order it goes, counting from zero. The
	// set is closed up around it, and a place beyond the end of the set is the
	// end of the set rather than a refusal.
	Position int `json:"position"`
}

// WriteEntryView is a view as the player states it. There is nothing about a
// view the server decides, so it is the read view whole.
type WriteEntryView struct {
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
	Zoom          float64  `json:"zoom"`
}

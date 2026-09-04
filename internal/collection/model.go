package collection

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

// Collection is a group of scores that belong together without being played in
// any particular order: the pieces a book holds, the repertoire a band can be
// asked for.
//
// It is the other half of what a set is. A set is a gig — the same song may
// come round twice in it, and the order is what is played — while a collection
// is a shelf: order says nothing, and a score is in it or it is not. Everything
// else is the same, because it is the same music: it is shared by address, its
// entries carry the key the group plays a piece in, and every player has their
// own view of every entry.
type Collection struct {
	Id          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`

	// Entries are the pieces in the collection. They come back by title,
	// because there is no order in a collection to come back in and a list
	// somebody has to look through is a list they should be able to find
	// something in.
	Entries []Entry `json:"entries"`

	// SharedWith holds the addresses the collection is readable by. It is only
	// filled in for the owner: who else someone shares with is not the business
	// of the people they share with.
	SharedWith []string `json:"shared_with"`

	// IsOwner tells the caller whether this collection is theirs to change.
	IsOwner bool `json:"is_owner"`

	LastChangedAt time.Time  `json:"last_changed_at"`
	DeletedAt     *time.Time `json:"deleted_at"`
}

// Entry is one piece as it stands in a collection.
//
// Everything here but View is the same for everyone the collection is shared
// with: it is what the group does with the piece, and it is the owner's to say.
// View is the caller's own and nobody else's.
//
// There is no position. Where a piece comes in a collection is not a thing a
// collection has an answer to, and a number nobody means anything by is a
// number somebody will end up sorting on.
type Entry struct {
	Id string `json:"id"`

	// ScoreId is the piece, and nil for one that is in the collection but not
	// in here — a page of a book that has yet to be scanned.
	//
	// A score is in a collection at most once. The pieces that have none are
	// outside that rule: they are told apart by what is written next to them,
	// and two lines of a book nobody has scanned are two pieces.
	ScoreId *string `json:"score_id"`

	Description string `json:"description"`

	// Transposition is how far the group plays this one from where it is
	// written. It is the arrangement rather than anyone's reading of it.
	Transposition int `json:"transposition"`

	// View is how the caller looks at this entry, which is theirs alone.
	View EntryView `json:"view"`
}

// EntryView is how one player looks at one entry of a collection.
//
// A collection says what the group plays; a view says what one player looks at
// while they play it. Playing a piece a tone down is the group's decision and
// reading it in another key because of the instrument it is played on is the
// player's, so they are two things rather than one: a saxophone player
// transposing their part changes nothing for the pianist, and the pianist
// wanting the piano staff alone on screen changes nothing for the singer.
//
// An entry a player has never looked at differently has the zero value, which
// is the view every entry starts with: as written, every part on screen.
type EntryView struct {
	// Transposition is on top of the entry's rather than instead of it.
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
	Zoom          float64  `json:"zoom"`
}

// WriteCollection is what a collection is, as the client states it: the group
// of pieces, and who may read it. What is in it is not here — an entry is a
// resource of its own, so a collection is created empty and filled afterwards.
type WriteCollection struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	SharedWith  []string `json:"shared_with"`
}

// WriteEntry is one entry as the owner of the collection states it: what the
// group does with one piece, and nothing about how anybody looks at it. A view
// belongs to a player rather than to a collection, so writing an entry leaves
// every player's view of it alone, the owner's own included.
//
// Which entry it is, is not here either: it is named by whoever writes it, in
// the path. There is no position: a collection has no order to put one in.
type WriteEntry struct {
	// ScoreId is the piece, and nil for one that is in the collection but not
	// in here. A score that is already in the collection under another entry is
	// refused: a collection holds a piece once.
	ScoreId       *string `json:"score_id"`
	Description   string  `json:"description"`
	Transposition int     `json:"transposition"`
}

// WriteEntryView is a view as the player states it. There is nothing about a
// view the server decides, so it is the read view whole.
type WriteEntryView struct {
	Transposition int      `json:"transposition"`
	HiddenParts   []string `json:"hidden_parts"`
	Zoom          float64  `json:"zoom"`
}

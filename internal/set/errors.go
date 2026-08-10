package set

import (
	"errors"
	"fmt"
)

var ErrSetNotFound = errors.New("no set found with the given id")

// ErrSetEntryNotFound is an entry the caller cannot write a view of: it is not
// there, it is not in the set they named, or the set is not one they can read.
// Which of those it is, is not said: it would answer questions about other
// people's sets.
var ErrSetEntryNotFound = errors.New("no entry found with the given id in the given set")

var ErrNotSetOwner = errors.New("only the owner of a set can change it")

type ErrInvalidSet struct {
	Reason string
}

func (err *ErrInvalidSet) Error() string {
	return fmt.Sprintf("invalid set: %s", err.Reason)
}

// ErrInvalidSetEntry is one entry the caller has to fix, which is a different
// thing from a set they have to fix now that an entry is written on its own.
type ErrInvalidSetEntry struct {
	Reason string
}

func (err *ErrInvalidSetEntry) Error() string {
	return fmt.Sprintf("invalid set entry: %s", err.Reason)
}

type ErrUnknownScore struct {
	ScoreId string
}

func (err *ErrUnknownScore) Error() string {
	return fmt.Sprintf("no score exists with id %s", err.ScoreId)
}

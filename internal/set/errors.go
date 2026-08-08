package set

import (
	"fmt"

	"github.com/pkg/errors"
)

// ErrSetNotFound is returned for a set that does not exist and, deliberately,
// for one the caller may not see: which sets other people have is not something
// to be discovered by asking for ids.
var ErrSetNotFound = errors.New("no set found with the given id")

// ErrNotSetOwner is returned when someone tries to change a set that is only
// shared with them.
var ErrNotSetOwner = errors.New("only the owner of a set can change it")

// ErrInvalidSet describes a set the caller has to fix before it can be stored.
type ErrInvalidSet struct {
	Reason string
}

func (err *ErrInvalidSet) Error() string {
	return fmt.Sprintf("invalid set: %s", err.Reason)
}

// ErrUnknownScore is a set entry pointing at a score that does not exist.
type ErrUnknownScore struct {
	ScoreId string
}

func (err *ErrUnknownScore) Error() string {
	return fmt.Sprintf("no score exists with id %s", err.ScoreId)
}

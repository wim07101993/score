package set

import (
	"errors"
	"fmt"
)

var ErrSetNotFound = errors.New("no set found with the given id")

var ErrNotSetOwner = errors.New("only the owner of a set can change it")

type ErrInvalidSet struct {
	Reason string
}

func (err *ErrInvalidSet) Error() string {
	return fmt.Sprintf("invalid set: %s", err.Reason)
}

type ErrUnknownScore struct {
	ScoreId string
}

func (err *ErrUnknownScore) Error() string {
	return fmt.Sprintf("no score exists with id %s", err.ScoreId)
}

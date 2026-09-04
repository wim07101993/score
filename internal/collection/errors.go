package collection

import (
	"errors"
	"fmt"
)

var ErrCollectionNotFound = errors.New("no collection found with the given id")

// ErrCollectionEntryNotFound is an entry the caller cannot write a view of: it
// is not there, it is not in the collection they named, or the collection is
// not one they can read. Which of those it is, is not said: it would answer
// questions about other people's collections.
var ErrCollectionEntryNotFound = errors.New("no entry found with the given id in the given collection")

var ErrNotCollectionOwner = errors.New("only the owner of a collection can change it")

type ErrInvalidCollection struct {
	Reason string
}

func (err *ErrInvalidCollection) Error() string {
	return fmt.Sprintf("invalid collection: %s", err.Reason)
}

// ErrInvalidCollectionEntry is one entry the caller has to fix, which is a
// different thing from a collection they have to fix now that an entry is
// written on its own.
type ErrInvalidCollectionEntry struct {
	Reason string
}

func (err *ErrInvalidCollectionEntry) Error() string {
	return fmt.Sprintf("invalid collection entry: %s", err.Reason)
}

type ErrUnknownScore struct {
	ScoreId string
}

func (err *ErrUnknownScore) Error() string {
	return fmt.Sprintf("no score exists with id %s", err.ScoreId)
}

// ErrScoreAlreadyInCollection is the one refusal a set has no equivalent of: a
// collection holds a piece once, and this is what an entry naming a score that
// is already in it under another entry is answered with.
//
// It names the entry the score is already in rather than only the score,
// because what the caller almost always wants next is that entry: a client
// adding a piece that is already there should be able to point at it rather
// than ask again.
type ErrScoreAlreadyInCollection struct {
	ScoreId string
	EntryId string
}

func (err *ErrScoreAlreadyInCollection) Error() string {
	return fmt.Sprintf("score %s is already in this collection, as entry %s",
		err.ScoreId, err.EntryId)
}

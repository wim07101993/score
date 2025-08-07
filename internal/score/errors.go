package score

import (
	"fmt"

	"github.com/pkg/errors"
)

type ErrInvalidMusicXml struct {
	Cause error
}

func (err *ErrInvalidMusicXml) String() string {
	return err.Error()
}

func (err *ErrInvalidMusicXml) Error() string {
	return fmt.Sprintf("Invalid music-xml file: %s", err.Cause)
}

var ErrScoreNotFound = errors.New("no score found with the given id")

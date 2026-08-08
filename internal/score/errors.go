package score

import "errors"

var (
	ErrScoreNotFound   = errors.New("no score found with the given id")
	ErrInvalidMusicXml = errors.New("invalid music-xml document")
)

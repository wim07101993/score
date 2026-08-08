package score

import "time"

// Score is a piece of sheet music as this package knows it: the metadata read
// out of the music-xml document when it was stored.
type Score struct {
	Id            string    `json:"id"`
	Work          Work      `json:"work"`
	Movement      Movement  `json:"movement"`
	Creators      Creators  `json:"creators"`
	Languages     []string  `json:"languages"`
	Instruments   []string  `json:"instruments"`
	LastChangedAt time.Time `json:"last_changed_at"`
	Tags          []string  `json:"tags"`
}

type Work struct {
	Title  string `json:"title"`
	Number string `json:"number"`
}

type Movement struct {
	Title  string `json:"title"`
	Number string `json:"number"`
}

type Creators struct {
	Composers []string `json:"composers"`
	Lyricists []string `json:"lyricists"`
}

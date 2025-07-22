package score

import "time"

type Score struct {
	Id            string    `json:"id"`
	Work          Work      `json:"work"`
	Movement      Movement  `json:"movement"`
	Creators      Creators  `json:"creators"`
	Languages     []string  `json:"languages"`
	Instruments   []string  `json:"instruments"`
	LastChangedAt time.Time `json:"lastChangedAt"`
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

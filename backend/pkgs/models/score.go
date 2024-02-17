package models

type Score struct {
	Title     string
	Composers []string
	Lyricists []string
	PartList  []PartGroup
}

type PartGroup struct {
	GroupSymbols []string
	number       int
}

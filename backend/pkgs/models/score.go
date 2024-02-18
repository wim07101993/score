package models

type Score struct {
	Title     string
	Composers []string
	Lyricists []string
	PartGroup *PartGroup
}

type PartGroup struct {
	Id         string
	Symbol     string
	PartGroups []*PartGroup
	Parts      []*Part
}

type Part struct {
	Id                  string
	Name                string
	NameDisplay         string
	Abbreviation        string
	AbbreviationDisplay string
	Instrument          string
}

package models

type Score struct {
	Title     string
	Composers []string
	Lyricists []string
	Parts     *PartGroup
}

func (s *Score) Instruments() []string {
	return s.Parts.Instruments()
}

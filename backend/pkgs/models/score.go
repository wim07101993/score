package models

type Score struct {
	Title     string
	Composers []string
	Lyricists []string
	Parts     *PartGroup
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
	Measures            []*Measure
}

type Measure struct {
	Number        int
	Key           *Key
	TimeSignature *TimeSignature
	Staves        []Stave
	Transpose     *Transpose
}

type Key struct {
	Tone string
	Mode string
}

type TimeSignature struct {
	Beats      int
	BeatLength int
}

type Stave struct {
	Number    int
	Clef      Clef
	Metronome *Metronome
}

type Clef struct {
	Sign string
	Line int
}

type Metronome struct {
	BeatUnit  string
	PerMinute string
}

type Transpose struct {
	Diatonic     int
	Chromatic    float64
	OctaveChange int
	Double       bool
}

func (pg *PartGroup) Part(partId string) *Part {
	for _, p := range pg.Parts {
		if p != nil && p.Id == partId {
			return p
		}
	}
	for _, pg := range pg.PartGroups {
		if pt := pg.Part(partId); pt != nil {
			return pt
		}
	}
	return nil
}

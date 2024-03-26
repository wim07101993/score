package musicxml

import "time"

const (
	CreatorComposer = "creator"
	CreatorLyricist = "lyricist"
)

type Creator struct {
	Type  string
	Value string
}

type Encoding struct {
	Date time.Time
}

type Identification struct {
	Creators []*Creator
	Encoding *Encoding
}

type Work struct {
	Title string
}

type Defaults struct {
	LyricLanguage string
}

type PartListItem = interface{}

type PartGroup struct {
	Type   string
	Number int
	Symbol string
}

type Instrument struct {
	Id     string
	Name   string
	Sound  string
	IsSolo bool
}

type ScorePart struct {
	Id                  string
	Identification      *Identification
	Name                string
	NameDisplay         string
	Abbreviation        string
	AbbreviationDisplay string
	Instrument          *Instrument
}

type Key struct {
	Fifths int
	Mode   string
}

type TimeSignature struct {
	Symbol   string
	Beats    int
	BeatType int
}

type Clef struct {
	Number int
	Sign   string
	Line   int
}

type StaffDetails struct {
	Number int
}

type Transpose struct {
	Diatonic     int
	Chromatic    int
	OctaveChange int
}

type MeasureAttributes struct {
	Divisions    int
	Key          *Key
	Time         *TimeSignature
	Staves       int
	Clef         *Clef
	StaffDetails *StaffDetails
	Transpose    *Transpose
}

type DirectionType = interface{}

type Metronome struct {
	BeatUnit  string
	PerMinute int
}

type Direction struct {
	DirectionTypes []DirectionType
	Voice          int
	Staff          int
}

type Pitch struct {
	Step   string
	Octave int
	Alter  int
}

type Beam struct {
	Number int
	Type   string
}

type Lyric struct {
	Number   string
	Syllabic string
	Text     string
}

type Rest struct {
	Measure bool
}

type Note struct {
	Pitch      *Pitch
	Duration   int
	Instrument string
	Voice      int
	Stem       string
	Type       string
	Beams      []*Beam
	Lyrics     []*Lyric
	Staff      int
	dotCount   int
	Rest       *Rest
}

type Repeat struct {
	Direction string
}

type Barline struct {
	Location string
	Style    string
	Repeat   *Repeat
}

type HarmonyRoot struct {
	Step  string
	Alter string
}

type Harmony struct {
	Root  *HarmonyRoot
	Kind  string
	Staff int
}

type Measure struct {
	Number     string
	Attributes *MeasureAttributes
	Directions []*Direction
	Notes      []*Note
	Barlines   []*Barline
	Harmonies  []*Harmony
}

type Part struct {
	Id       string
	Measures []*Measure
}

type ScorePartwise struct {
	Work           *Work
	Identification *Identification
	Defaults       *Defaults
	PartList       []PartListItem
	Parts          []*Part
}

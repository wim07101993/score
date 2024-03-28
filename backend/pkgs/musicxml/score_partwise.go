package musicxml

import "time"

type TypedText struct {
	Type  string
	Value string
}

type Encoding struct {
	Date time.Time
}

type Identification struct {
	Creators []*TypedText
	Encoding *Encoding
	Rights   []*TypedText
	Relation []*TypedText
}

type Work struct {
	Title  string
	Number string
}

type Defaults struct {
	LyricLanguage string
}

type PartListItem struct {
	PartGroup *PartGroup
	ScorePart *ScorePart
}

type PartGroup struct {
	Type   string
	Number int
	Symbol string
}

type Instrument struct {
	Id       string
	Name     string
	Sound    string
	IsSolo   bool
	Ensemble *int
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
	Number       int
	Sign         string
	Line         int
	OctaveChange int
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

type Dynamic struct {
	Values []string
}

type DirectionType struct {
	Metronome *Metronome
	Words     []string
	Dynamics  []*Dynamic
}

type Metronome struct {
	BeatUnit  string
	PerMinute int
}

type Offset struct {
	Divisions float32
	Sound     bool
}

type Sound struct {
	ToCoda         string
	Offset         *Offset
	TimeOnly       string
	Tempo          float32
	Dynamics       float32
	DaCapo         bool
	Coda           string
	Divisions      float32
	ForwardRepeat  bool
	Fine           string
	Pizzicato      bool
	Pan            float32
	Elevation      float32
	DamperPedal    string
	SoftPedal      string
	SostenutoPedal string
	Segno          bool
	DalSegno       bool
}

type Direction struct {
	DirectionTypes []DirectionType
	Voice          int
	Staff          int
	Offset         *Offset
	Sound          *Sound
	IsDirective    bool
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

type Extend struct {
	Type string
}

type Lyric struct {
	Number   string
	Syllabic string
	Text     string
	Extend   *Extend
}

type Rest struct {
	Measure bool
}

type Slur struct {
	Type        string
	Orientation string
	Number      int
}

type Tied struct {
	Type        string
	Orientation string
}

type TupletPortion struct {
	Number   int
	Type     string
	DotCount int
}

type TupletValue struct {
	Actual *TupletPortion
	Normal *TupletPortion
}

type Tuplet struct {
	Type       string
	Number     int
	Bracket    bool
	ShowNumber string
	ShowType   string
	Values     []TupletValue
}

type Fermata struct {
	Shape      string
	IsInverted bool
}

type Notation struct {
	Slurs    []*Slur
	Ties     []*Tied
	Tuplets  []*Tuplet
	Dynamics []*Dynamic
	Fermatas []*Fermata
}

type Accidental struct {
	Value string
}

type TimeModificationItem struct {
	NormalType string
	NormalDot  struct{}
}

type TimeModification struct {
	ActualNotes int
	NormalNotes int
	Items       []TimeModificationItem
}

type NoteHead struct {
	Value       string
	Filled      bool
	Parentheses bool
}

type Note struct {
	Pitch             *Pitch
	Duration          int
	Instruments       []string
	Voice             int
	Stem              string
	Type              string
	Beams             []*Beam
	Lyrics            []*Lyric
	Staff             int
	dotCount          int
	Rest              *Rest
	IsChord           bool
	Ties              []*Tie
	Notations         []*Notation
	Accidentals       []*Accidental
	TimeModifications []*TimeModification
	Head              *NoteHead
	Cue               bool
}

type Tie struct {
	Type string
}

type Backup struct {
	Duration float32
}

type Repeat struct {
	Direction string
}

type Ending struct {
	Number string
	Type   string
}

type Barline struct {
	Location string
	Style    string
	Repeat   *Repeat
	Ending   *Ending
}

type HarmonyRoot struct {
	Step  string
	Alter string
}

type Bass struct {
	Step  string
	Alter string
}

type DegreeValue struct {
	Value  int
	Symbol string
	Text   string
}

type DegreeType struct {
	Value string
	Text  string
}

type DegreeAlter struct {
	Value     float32
	PlusMinus bool
}

type Degree struct {
	Value *DegreeValue
	Alter *DegreeAlter
	Type  *DegreeType
}

type Harmony struct {
	Root    *HarmonyRoot
	Kind    string
	Staff   int
	Bass    *Bass
	Degrees []*Degree
}

type Forward struct {
	Duration float32
}

type MeasureElement struct {
	Attributes *MeasureAttributes
	Direction  *Direction
	Note       *Note
	Barline    *Barline
	Harmony    *Harmony
	Backup     *Backup
	Forward    *Forward
}

type Measure struct {
	Number   string
	Elements []MeasureElement
}

type Part struct {
	Id string
	// Measures is a list of all the measures of this part.
	// The order of this list is important.
	Measures []*Measure
}

type ScorePartwise struct {
	Work           *Work
	Identification *Identification
	Defaults       *Defaults
	PartList       []PartListItem
	Parts          []*Part
	MovementNumber string
	MovementTitle  string
}

package musicxml

import (
	"strings"
	"time"
)

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

const (
	PartGroupType_Start = "start"
	PartGroupType_Stop  = "stop"
)

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

type DisplayName struct {
	Items []DisplayNameItem
}

func (name DisplayName) String() string {
	switch len(name.Items) {
	case 0:
		return ""
	case 1:
		return name.Items[0].DisplayText + name.Items[0].AccidentalText
	}

	b := strings.Builder{}
	for _, item := range name.Items {
		if len(item.DisplayText) != 0 {
			b.WriteString(item.DisplayText)
		}
		if len(item.AccidentalText) != 0 {
			b.WriteString(item.AccidentalText)
		}
	}
	return b.String()
}

type DisplayNameItem struct {
	DisplayText    string
	AccidentalText string
}

type ScorePart struct {
	Id                  string
	Identification      *Identification
	Name                string
	NameDisplay         *DisplayName
	Abbreviation        string
	AbbreviationDisplay *DisplayName
	Instruments         []*Instrument
}

type Key struct {
	Fifths int
	Mode   string
}

type TimeSignature struct {
	Symbol   string
	Beats    int
	BeatType string
}

type Clef struct {
	Number       int
	Sign         string
	Line         int
	OctaveChange int
}

type StaffTuning struct {
	Line   int
	step   string
	octave int
	alter  float32
}

type StaffDetails struct {
	Number int
	Lines  *int
	Tuning []*StaffTuning
}

type Transpose struct {
	Diatonic     *int
	Chromatic    int
	OctaveChange *int
}

type MeasureAttributes struct {
	Divisions    float32
	Key          *Key
	Time         *TimeSignature
	Staves       int
	Clefs        []*Clef
	StaffDetails []*StaffDetails
	Transposes   []*Transpose
}

type Dynamic struct {
	Values []string
}

type Wedge struct {
	Type   string
	Number int
}

type OctaveShift struct {
	Type   string
	Number int
	Size   int
}

type DirectionType struct {
	Metronome      *Metronome
	Words          []string
	Dynamics       []*Dynamic
	Wedge          *Wedge
	OtherDirection string
	OctaveShift    *OctaveShift
	Segno          bool
}

type Metronome struct {
	BeatUnit    string
	PerMinute   int
	BeatUnitDot bool
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
	Voice          string
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

type Articulations struct {
	Tenuto     bool
	Staccato   bool
	BreathMark bool
	Accent     bool
}

type Slide struct {
	Type string
}

type Arpeggiate struct {
}

type Technical struct {
	Fret   int
	String int
}

type Glissando struct {
	Type     string
	Number   int
	LineType string
}

type Notation struct {
	Slurs         []*Slur
	Ties          []*Tied
	Tuplets       []*Tuplet
	Dynamics      []*Dynamic
	Fermatas      []*Fermata
	Articulations []*Articulations
	Slides        []*Slide
	Arpeggiate    []*Arpeggiate
	Technical     []*Technical
	Glissandos    []*Glissando
}

type Accidental struct {
	Value string
}

type TimeModificationItem struct {
	NormalType string
	HasDot     bool
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

type Grace struct {
	Slash bool
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
	Grace             *Grace
	IsUnpitched       bool
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

type FirstFret struct {
	Value    int
	Text     string
	Location string
}

type Fingering struct {
	Value        string
	Substitution bool
	Alternate    bool
}

type Barre struct {
	Type string
}

type FrameNote struct {
	String    int
	Fret      int
	Fingering *Fingering
	Barre     *Barre
}

type Frame struct {
	Strings   int
	Frets     int
	FirstFret *FirstFret
	Notes     []*FrameNote
}

type Harmony struct {
	Root    *HarmonyRoot
	Kind    string
	Staff   int
	Bass    *Bass
	Degrees []*Degree
	Frame   *Frame
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

func NewMeasureAttributes() MeasureAttributes {
	return MeasureAttributes{}
}

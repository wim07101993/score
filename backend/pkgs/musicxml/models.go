package musicxml

import "encoding/xml"

type ScorePartWise struct {
	XMLName        xml.Name        `xml:"score-partwise"`
	Work           *Work           `xml:"work"`
	Identification *Identification `xml:"identification"`
	PartList       PartList        `xml:"part-list"`
	Parts          []Part          `xml:"part"`
}

type Work struct {
	Title string `xml:"work-title"`
}

type Identification struct {
	Creators []TypedText `xml:"creator"`
}

type TypedText struct {
	Type  string `xml:"type,attr"`
	Value string `xml:",chardata"`
}

type PartList struct {
	Items PartListItem
}

type PartListItem interface {
	when(
		pg func(pg PartGroup))
}

type PartGroup struct {
	XMLName xml.Name     `xml:"part-group"`
	Type    StartOrStop  `xml:"type"`
	Number  int          `xml:"number"`
	Symbol  *GroupSymbol `xml:"group-symbol"`
}

type StartOrStop string

const (
	StartOrStop_Start StartOrStop = "start"
	StartOrStop_Stop              = "stop"
)

type GroupSymbol string

const (
	GroupSymbol_Brace   GroupSymbol = "brace"
	GroupSymbol_Line                = "line"
	GroupSymbol_Bracket             = "bracket"
	GroupSymbol_Square              = "square"
)

type ScorePart struct {
	XMLName      xml.Name          `xml:"score-part"`
	Name         NameDisplay       `xml:"part-name-display"`
	Abbreviation *NameDisplay      `xml:"part-abbreviation-display"`
	Instruments  []ScoreInstrument `xml:"score-instrument"`
}

type NameDisplay struct {
	DisplayText    string   `xml:"display-text"`
	AccidentalText string   `xml:"accidental-text"`
	ShouldPrint    *YesOrNo `xml:"yes-no,attr"`
}

type YesOrNo string

const (
	Yes = "yes"
	No  = "no"
)

type ScoreInstrument struct {
	Id                     string `xml:"id"`
	InstrumentName         string `xml:"instrument-name"`
	InstrumentAbbreviation string `xml:"instrument-abbreviation"`
}

type Part struct {
	Id       string    `xml:"id"`
	Measures []Measure `xml:"measures"`
}

type Measure struct {
	Number string `xml:"number"`
	// Musical notation duration is commonly represented as fractions. The
	// divisions element indicates how many divisions per quarter note are used
	// to indicate a note's duration.
	//
	// For example, if duration = 1 and divisions = 2, this is an eighth note
	// duration. Duration and divisions are used directly for generating sound
	// output, so they must be chosen to take tuplets into account. Using a
	// divisions element lets us use just one number to represent a duration
	// for each note in the score, while retaining the full power of a
	// fractional representation. If maximum compatibility with Standard
	// MIDI 1.0 files is important, do not have the divisions value exceed
	// 16383.
	Divisions Divisions `xml:"divisions"`
	// The key element represents a key signature. The optional number
	// attribute refers to staff numbers. If absent, the key signature applies
	// to all staves in the part.
	Key *Key `xml:"key"`
	// Time signatures are represented by the beats element for the numerator
	// and the beat-type element for the denominator.
	Time *Time `xml:"time"`
	// The staves element is used if there is more than one staff represented
	// in the given part (e.g., 2 staves for typical piano parts). If absent,
	// a value of 1 is assumed. Staves are ordered from top to bottom in a part
	// in numerical order, with staff 1 above staff 2.
	Staves uint `xml:"staves"`
	// Clefs are represented by a combination of sign, line, and
	// clef-octave-change elements.
	Clefs     []Clef     `xml:"clef"`
	Direction *Direction `xml:"direction"`
	// TODO
}

type Divisions float32

const Divisions_Default = 256

// Key represents a key signature. The optional number attribute refers to staff
// numbers. If absent, the key signature applies to all staves in the part.
// Key signatures appear at the start of each system unless the print-object
// attribute has been set to "no".
type Key struct {
	TraditionalKey *TraditionalKey
}

// TraditionalKey represents a traditional key signature using the cycle of
// fifths.
type TraditionalKey struct {
	Fifths Fifths    `xml:"fifths"`
	Cancel KeyCancel `xml:"cancel"`
	Mode   Mode      `xml:"mode"`
}

// KeyCancel indicates that the old key signature should be cancelled before
// the new one appears. This will always happen when changing to C major or
// A minor and need not be specified then. The cancel value matches the fifths
// value of the cancelled key signature (e.g., a cancel of -2 will provide an
// explicit cancellation for changing from B flat major to F major). The
// optional location attribute indicates where the cancellation appears
// relative to the new key signature.
type KeyCancel struct {
	Fifths   Fifths         `xml:",chardata"`
	Location CancelLocation `xml:"cancel-location,attr"`
}

// Time signatures are represented by the beats element for the numerator and
// the beat-type element for the denominator. The symbol attribute is used to
// indicate common and cut time symbols as well as a single number display.
// Multiple pairs of beat and beat-type elements are used for composite time
// signatures with multiple denominators, such as 2/4 + 3/8. A composite such
// as 3+2/8 requires only one beat/beat-type pair.
//
// The print-object attribute allows a time signature to be specified but not
// printed, as is the case for excerpts from the middle of a score. The value
// is "yes" if not present. The optional number attribute refers to staff
// numbers within the part. If absent, the time signature applies to all staves
// in the part.
type Time struct {
	TimeSignature *TimeSignature
}

// TimeSignature is represented by the beats element for the numerator and
// the beat-type element for the denominator.
type TimeSignature struct {
	// The beats element indicates the number of beats, as found in the
	// numerator of a time signature.
	Beats string `xml:"beats"`
	// The beat-type element indicates the beat unit, as found in the
	// denominator of a time signature.
	BeatType string `xml:"beat-type"`
}

// Fifths represents the number of flats or sharps in a traditional key
// signature. Negative numbers are used for flats and positive numbers for
// sharps, reflecting the key's placement within the circle of fifths (hence the
// type name).
type Fifths int

// CancelLocation is used to indicate where a key signature cancellation
// appears relative to a new key signature: to the left, to the right, or before
// the barline and to the left. It is left by default. For mid-measure key
// elements, a cancel-location of before-barline should be treated like a
// cancel-location of left.
type CancelLocation string

const (
	CancelLocation_Left          = "left"
	CancelLocation_Right         = "right"
	CancelLocation_BeforeBarline = "before-barline"
)

// Mode is used to specify major/minor and other mode distinctions. Valid mode
// values include major, minor, dorian, phrygian, lydian, mixolydian, aeolian,
// ionian, locrian, and none.
type Mode string

const (
	Mode_Major      = "major"
	Mode_Minor      = "minor"
	Mode_Dorian     = "dorian"
	Mode_Phrygian   = "phrygian"
	Mode_Lydian     = "lydian"
	Mode_Mixolydian = "mixolydian"
	Mode_Aeolian    = "aeolian"
	Mode_Ionian     = "ionian"
	Mode_Locrian    = "locrian"
	Mode_None       = "none"
)

// Clef is represented by a combination of sign, line, and clef-octave-change
// elements. The optional number attribute refers to staff numbers within the
// part. A value of 1 is assumed if not present.
//
// Sometimes clefs are added to the staff in non-standard line positions, either
// to indicate cue passages, or when there are multiple clefs present
// simultaneously on one staff. In this situation, the additional attribute is
// set to "yes" and the line value is ignored. The size attribute is used for
// clefs where the additional attribute is "yes". It is typically used to
// indicate cue clefs.
//
// Sometimes clefs at the start of a measure need to appear after the barline
// rather than before, as for cues or for use after a repeated section. The
// after-barline attribute is set to "yes" in this situation. The attribute is
// ignored for mid-measure clefs.
//
// Clefs appear at the start of each system unless the print-object attribute
// has been set to "no" or the additional attribute has been set to "yes".
type Clef struct {
	// The sign element represents the clef symbol.
	Sign ClefSign `xml:"clef-sign"`
	// Line numbers are counted from the bottom of the staff. They are only
	// needed with the G, F, and C signs in order to position a pitch
	// correctly on the staff. Standard values are 2 for the G sign
	// (treble clef), 4 for the F sign (bass clef), and 3 for the C sign
	// (alto clef). Line values can be used to specify positions outside the
	// staff, such as a C clef positioned in the middle of a grand staff.
	Line StaffLinePosition `xml:"staff-line-position"`
	// The clef-octave-change element is used for transposing clefs. A treble
	// clef for tenors would have a value of -1.
	OctaveChange int `xml:"clef-octave-change"`
	// Number indicates staff numbers within a multi-staff part. Staves are
	// numbered from top to bottom, with 1 being the top staff on a part.
	Number StaffNumber `xml:"staff-number,attr"`
}

// ClefSign type represents the different clef symbols. The jianpu sign
// indicates that the music that follows should be in jianpu numbered notation,
// just as the TAB sign indicates that the music that follows should be in
// tablature notation. Unlike TAB, a jianpu sign does not correspond to a
// visual clef notation.
//
// The none sign is deprecated as of MusicXML 4.0. Use the clef element's
// print-object attribute instead. When the none sign is used, notes should be
// displayed as if in treble clef.
type ClefSign string

const (
	ClefSign_G          = "G"
	ClefSign_F          = "F"
	ClefSign_C          = "C"
	ClefSign_Percussion = "percussion"
	ClefSign_Tab        = "TAB"
	ClefSign_Jianpu     = "jianpu"
	ClefSign_None       = "none"
)

// StaffLinePosition indicates the line position on a given staff. Staff lines
// are numbered from bottom to top, with 1 being the bottom line on a staff. A
// staff-line-position value can extend beyond the range of the lines on the
// current staff.
type StaffLinePosition int

const (
	StaffLinePosition_G = 2
	StaffLinePosition_F = 4
	StaffLinePosition_C = 3
)

// StaffNumber indicates staff numbers within a multi-staff part. Staves are
// numbered from top to bottom, with 1 being the top staff on a part.
type StaffNumber uint

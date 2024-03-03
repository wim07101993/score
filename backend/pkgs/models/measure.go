package models

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

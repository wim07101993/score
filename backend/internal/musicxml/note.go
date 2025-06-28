package musicxml

import (
	"encoding/xml"
	"strconv"
)

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

func readNote(r xml.TokenReader, element xml.StartElement) (note *Note, err error) {
	note = &Note{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "chord":
				if note.IsChord {
					return &FieldAlreadySet{element, el}
				}
				note.IsChord = true
				err = ReadUntilClose(r, el)
			case "pitch":
				if note.Pitch != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Pitch, err = readPitch(r, el)
			case "duration":
				if note.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Duration, err = ReadInt(r, el)
			case "instrument":
				instrument, err := readInstrumentReference(r, el)
				if err != nil {
					return err
				}
				note.Instruments = append(note.Instruments, instrument)
			case "voice":
				if note.Voice != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Voice, err = ReadInt(r, el)
			case "type":
				if note.Type != "" {
					return &FieldAlreadySet{element, el}
				}
				note.Type, err = ReadString(r, el)
			case "stem":
				if note.Stem != "" {
					return &FieldAlreadySet{element, el}
				}
				note.Stem, err = ReadString(r, el)
			case "staff":
				if note.Staff != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Staff, err = ReadInt(r, el)
			case "beam":
				beam, err := readBeam(r, el)
				if err != nil {
					return nil
				}
				note.Beams = append(note.Beams, beam)
			case "lyric":
				lyric, err := readLyric(r, el)
				if err != nil {
					return err
				}
				note.Lyrics = append(note.Lyrics, lyric)
			case "dot":
				note.dotCount++
				err = ReadUntilClose(r, el)
			case "rest":
				if note.Rest != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Rest, err = readRest(r, el)
			case "tie":
				tie, err := readTie(r, el)
				if err != nil {
					return err
				}
				note.Ties = append(note.Ties, tie)
			case "notations":
				notation, err := readNotation(r, el)
				if err != nil {
					return err
				}
				note.Notations = append(note.Notations, notation)
			case "accidental":
				accidental, err := readAccidental(r, el)
				if err != nil {
					return err
				}
				note.Accidentals = append(note.Accidentals, accidental)
			case "time-modification":
				mod, err := readTimeModification(r, el)
				if err != nil {
					return err
				}
				note.TimeModifications = append(note.TimeModifications, mod)
			case "notehead":
				if note.Head != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Head, err = readNoteHead(r, el)
			case "cue":
				if note.Cue {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				note.Cue = true
			case "grace":
				if note.Grace != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Grace, err = readGrace(r, el)
			case "unpitched":
				if note.IsUnpitched {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				note.IsUnpitched = true
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return note, err
}

func writeNote(w *xml.Encoder, name string, note *Note) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if note.Grace != nil {
				return writeGrace(w, "grace", note.Grace)
			}
			return nil
		},
		func() error {
			if note.Cue {
				return WriteObject(w, "cue", nil)
			}
			return nil
		},
		func() error {
			if note.IsChord {
				return WriteObject(w, "chord", nil)
			}
			return nil
		},
		func() error {
			if note.Pitch != nil {
				return writePitch(w, "pitch", note.Pitch)
			}
			return nil
		},
		func() error {
			if note.IsUnpitched {
				return WriteObject(w, "unpitched", nil)
			}
			return nil
		},
		func() error {
			if note.Rest != nil {
				return writeRest(w, "rest", note.Rest)
			}
			return nil
		},
		func() error {
			if note.Duration != 0 {
				return WriteString(w, "duration", strconv.Itoa(note.Duration), nil)
			}
			return nil
		},
		func() error {
			for _, tie := range note.Ties {
				if err = writeTie(w, "tie", tie); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, instrument := range note.Instruments {
				if err = writeInstrumentReference(w, "instrument", instrument); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if note.Voice != 0 {
				return WriteString(w, "voice", strconv.Itoa(note.Voice), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "type", note.Type, nil)
		},
		func() error {
			for i := 0; i < note.dotCount; i++ {
				if err = WriteObject(w, "dot", nil); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, accidental := range note.Accidentals {
				if err = writeAccidental(w, "accidental", accidental); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, mod := range note.TimeModifications {
				if err = writeTimeModification(w, "time-modification", mod); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if note.Stem == "" {
				return nil
			}
			return WriteString(w, "stem", note.Stem, nil)
		},
		func() error {
			if note.Head != nil {
				return writeNoteHead(w, "notehead", note.Head)
			}
			return nil
		},
		func() error {
			return WriteString(w, "staff", strconv.Itoa(note.Staff), nil)
		},
		func() error {
			for _, beam := range note.Beams {
				if err = writeBeam(w, "beam", beam); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, notation := range note.Notations {
				if err = writeNotation(w, "notations", notation); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, lyric := range note.Lyrics {
				if err = writeLyric(w, "lyric", lyric); err != nil {
					return err
				}
			}
			return nil
		})
}

package musicxml

import (
	"encoding/xml"
	"strconv"
)

type FrameNote struct {
	String    int
	Fret      int
	Fingering *Fingering
	Barre     *Barre
}

func readFrameNote(r xml.TokenReader, element xml.StartElement) (note *FrameNote, err error) {
	note = &FrameNote{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "string":
				if note.String != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.String, err = ReadInt(r, el)
			case "fret":
				if note.Fret != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Fret, err = ReadInt(r, el)
			case "fingering":
				if note.Fingering != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Fingering, err = readFingering(r, el)
			case "barre":
				if note.Barre != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Barre, err = readBarre(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return note, err
}

func writeFrameNote(w *xml.Encoder, name string, note *FrameNote) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "string", strconv.Itoa(note.String), nil)
		},
		func() error {
			return WriteString(w, "fret", strconv.Itoa(note.Fret), nil)
		},
		func() error {
			if note.Fingering != nil {
				return writeFingering(w, "fingering", note.Fingering)
			}
			return nil
		},
		func() error {
			if note.Barre != nil {
				return writeBarre(w, "barre", note.Barre)
			}
			return nil
		})
}

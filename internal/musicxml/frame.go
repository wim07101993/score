package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Frame struct {
	Strings   int
	Frets     int
	FirstFret *FirstFret
	Notes     []*FrameNote
}

func readFrame(r xml.TokenReader, element xml.StartElement) (frame *Frame, err error) {
	frame = &Frame{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "frame-strings":
				if frame.Strings != 0 {
					return &FieldAlreadySet{element, el}
				}
				frame.Strings, err = ReadInt(r, el)
			case "frame-frets":
				if frame.Frets != 0 {
					return &FieldAlreadySet{element, el}
				}
				frame.Frets, err = ReadInt(r, el)
			case "first-fret":
				if frame.FirstFret != nil {
					return &FieldAlreadySet{element, el}
				}
				frame.FirstFret, err = readFirstFret(r, el)
			case "frame-read":
				note, err := readFrameNote(r, el)
				if err != nil {
					return err
				}
				frame.Notes = append(frame.Notes, note)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return frame, err
}

func writeFrame(w *xml.Encoder, name string, frame *Frame) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "frame-strings", strconv.Itoa(frame.Strings), nil)
		},
		func() error {
			return WriteString(w, "frame-frets", strconv.Itoa(frame.Frets), nil)
		},
		func() error {
			if frame.FirstFret != nil {
				return writeFirstFret(w, "first-fret", frame.FirstFret)
			}
			return nil
		},
		func() error {
			for _, note := range frame.Notes {
				if err = writeFrameNote(w, "frame-note", note); err != nil {
					return err
				}
			}
			return nil
		})
}

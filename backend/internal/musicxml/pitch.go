package musicxml

import (
	"encoding/xml"
	"fmt"
	"strconv"
)

type Step string

type Pitch struct {
	Step   Step
	Octave int
	Alter  float32
}

func readPitch(r xml.TokenReader, element xml.StartElement) (pitch *Pitch, err error) {
	pitch = &Pitch{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "step":
				if pitch.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				s, err := ReadString(r, el)
				if err != nil {
					return err
				}
				pitch.Step = Step(s)
			case "octave":
				if pitch.Octave != 0 {
					return &FieldAlreadySet{element, el}
				}
				pitch.Octave, err = ReadInt(r, el)
			case "alter":
				if pitch.Alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				pitch.Alter, err = ReadFloat32(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return pitch, err
}

func writePitch(w *xml.Encoder, name string, pitch *Pitch) (err error) {
	def := Pitch{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "step", string(pitch.Step), nil)
		},
		func() error {
			if pitch.Alter != def.Alter {
				return WriteString(w, "alter", fmt.Sprintf("%g", pitch.Alter), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "octave", strconv.Itoa(pitch.Octave), nil)
		})
}

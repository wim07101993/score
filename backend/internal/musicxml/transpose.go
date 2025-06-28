package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Transpose struct {
	Diatonic     *int
	Chromatic    int
	OctaveChange *int
}

func readTranspose(r xml.TokenReader, element xml.StartElement) (transpose *Transpose, err error) {
	transpose = &Transpose{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "diatonic":
				if transpose.Diatonic != nil {
					return &FieldAlreadySet{element, el}
				}
				diatonic, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				transpose.Diatonic = &diatonic
			case "chromatic":
				if transpose.Chromatic != 0 {
					return &FieldAlreadySet{element, el}
				}
				transpose.Chromatic, err = ReadInt(r, el)
			case "octave-change":
				if transpose.OctaveChange != nil {
					return &FieldAlreadySet{element, el}
				}
				octave, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				transpose.OctaveChange = &octave
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return transpose, err
}

func writeTranspose(w *xml.Encoder, name string, transpose *Transpose) (err error) {
	return WriteObject(w, name,
		nil,
		func() error {
			if transpose.Diatonic != nil {
				return WriteString(w, "diatonic", strconv.Itoa(*transpose.Diatonic), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "chromatic", strconv.Itoa(transpose.Chromatic), nil)
		},
		func() error {
			if transpose.OctaveChange != nil {
				return WriteString(w, "octave-change", strconv.Itoa(*transpose.OctaveChange), nil)
			}
			return nil
		},
	)
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"strconv"
)

type StaffTuning struct {
	Line   int
	step   string
	octave int
	alter  float32
}

func readTuning(r xml.TokenReader, element xml.StartElement) (tuning *StaffTuning, err error) {
	tuning = &StaffTuning{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "line":
				tuning.Line, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuning-step":
				if tuning.step != "" {
					return &FieldAlreadySet{element, el}
				}
				tuning.step, err = ReadString(r, el)
			case "tuning-octave":
				if tuning.octave != 0 {
					return &FieldAlreadySet{element, el}
				}
				tuning.octave, err = ReadInt(r, el)
			case "tuning-alter":
				if tuning.alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				tuning.alter, err = ReadFloat32(r, el)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tuning, err
}

func writeTuning(w *xml.Encoder, name string, tuning *StaffTuning) (err error) {
	def := StaffTuning{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "line"}, Value: strconv.Itoa(tuning.Line)},
		},
		func() error {
			return WriteString(w, "tuning-step", tuning.step, nil)
		},
		func() error {
			if tuning.alter != def.alter {
				return WriteString(w, "tuning-alter", fmt.Sprintf("%g", tuning.alter), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "tuning-octave", strconv.Itoa(tuning.octave), nil)
		})
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"strconv"
)

type MeasureAttributes struct {
	Divisions    float32
	Key          *Key
	Time         *TimeSignature
	Staves       int
	Clefs        []*Clef
	StaffDetails []*StaffDetails
	Transposes   []*Transpose
}

func NewMeasureAttributes() MeasureAttributes {
	return MeasureAttributes{}
}

func readMeasureAttributes(r xml.TokenReader, element xml.StartElement) (attr *MeasureAttributes, err error) {
	def := NewMeasureAttributes()
	a := NewMeasureAttributes()
	attr = &a
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "divisions":
				if attr.Divisions != 0 {
					return &FieldAlreadySet{element, el}
				}
				attr.Divisions, err = ReadFloat32(r, el)
			case "key":
				if attr.Key != nil {
					return &FieldAlreadySet{element, el}
				}
				attr.Key, err = readKey(r, el)
			case "time":
				if attr.Time != nil {
					return &FieldAlreadySet{element, el}
				}
				attr.Time, err = readTimeSignature(r, el)
			case "staves":
				if attr.Staves != def.Staves {
					return &FieldAlreadySet{element, el}
				}
				attr.Staves, err = ReadInt(r, el)
			case "clef":
				c, err := readClef(r, el)
				if err != nil {
					return err
				}
				attr.Clefs = append(attr.Clefs, c)
			case "staff-details":
				details, err := readStaffDetails(r, el)
				if err != nil {
					return err
				}
				attr.StaffDetails = append(attr.StaffDetails, details)
			case "transpose":
				tr, err := readTranspose(r, el)
				if err != nil {
					return err
				}
				attr.Transposes = append(attr.Transposes, tr)
			case "measure-style":
				err = ReadUntilClose(r, el) // IGNORE styling
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return attr, err
}

func writeMeasureAttributes(w *xml.Encoder, name string, attributes *MeasureAttributes) (err error) {
	def := MeasureAttributes{}
	return WriteObject(w, name,
		nil,
		func() error {
			if attributes.Divisions != def.Divisions {
				return WriteString(w, "divisions", fmt.Sprintf("%g", attributes.Divisions), nil)
			}
			return nil
		},
		func() error {
			if attributes.Key != nil {
				return writeKey(w, "key", attributes.Key)
			}
			return nil
		},
		func() error {
			if attributes.Time != nil {
				return writeTimeSignature(w, "time", attributes.Time)
			}
			return nil
		},
		func() error {
			if attributes.Staves != def.Staves {
				return WriteString(w, "staves", strconv.Itoa(attributes.Staves), nil)
			}
			return nil
		},
		func() error {
			for _, clef := range attributes.Clefs {
				if err := writeClef(w, "clef", clef); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, details := range attributes.StaffDetails {
				if err := writeStaffDetails(w, "staff-details", details); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, transpose := range attributes.Transposes {
				if err := writeTranspose(w, "transpose", transpose); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

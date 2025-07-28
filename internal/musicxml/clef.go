package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Clef struct {
	Number       int
	Sign         string
	Line         int
	OctaveChange int
}

func readClef(r xml.TokenReader, element xml.StartElement) (clef *Clef, err error) {
	clef = &Clef{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				clef.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "sign":
				if clef.Sign != "" {
					return &FieldAlreadySet{element, el}
				}
				clef.Sign, err = ReadString(r, el)
			case "line":
				if clef.Line != 0 {
					return &FieldAlreadySet{element, el}
				}
				clef.Line, err = ReadInt(r, el)
			case "clef-octave-change":
				if clef.OctaveChange != 0 {
					return &FieldAlreadySet{element, el}
				}
				clef.OctaveChange, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return clef, err
}

func writeClef(w *xml.Encoder, name string, clef *Clef) (err error) {
	def := Clef{}
	var attrs []xml.Attr
	if clef.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(clef.Number)})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if clef.Sign != def.Sign {
				return WriteString(w, "sign", clef.Sign, nil)
			}
			return nil
		},
		func() error {
			if clef.Line != def.Line {
				return WriteString(w, "line", strconv.Itoa(clef.Line), nil)
			}
			return nil
		},
		func() error {
			if clef.OctaveChange != def.OctaveChange {
				return WriteString(w, "clef-octave-change", strconv.Itoa(clef.OctaveChange), nil)
			}
			return nil
		})
}

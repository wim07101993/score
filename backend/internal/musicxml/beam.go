package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Beam struct {
	Number int
	Type   string
}

func readBeam(r xml.TokenReader, element xml.StartElement) (beam *Beam, err error) {
	beam = &Beam{Number: 1}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "number":
			beam.Number, err = strconv.Atoi(attr.Value)
			if err != nil {
				return beam, err
			}
		default:
			return beam, &UnknownAttribute{element, attr}
		}
	}

	beam.Type, err = ReadString(r, element)
	return beam, err
}

func writeBeam(w *xml.Encoder, name string, beam *Beam) (err error) {
	def := Beam{}
	var attrs []xml.Attr

	if beam.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(beam.Number)})
	}

	return WriteString(w, name, beam.Type, attrs)
}

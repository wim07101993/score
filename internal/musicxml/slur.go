package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Slur struct {
	Type        string
	Orientation string
	Number      int
}

func readSlur(r xml.TokenReader, element xml.StartElement) (slur *Slur, err error) {
	slur = &Slur{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "orientation":
				slur.Orientation = attr.Value
			case "type":
				slur.Type = attr.Value
			case "number":
				slur.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return slur, err
}

func writeSlur(w *xml.Encoder, name string, slur *Slur) (err error) {
	def := Slur{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: slur.Type},
	}
	if slur.Orientation != def.Orientation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "orientation"}, Value: slur.Orientation})
	}
	if slur.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(slur.Number)})
	}
	return WriteObject(w, name, attrs)
}

package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Wedge struct {
	Type   string
	Number int
}

func readWedge(r xml.TokenReader, element xml.StartElement) (wedge *Wedge, err error) {
	wedge = &Wedge{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				wedge.Number, err = strconv.Atoi(attr.Value)
			case "type":
				wedge.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return wedge, err
}

func writeWedge(w *xml.Encoder, name string, wedge *Wedge) (err error) {
	def := Wedge{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: wedge.Type},
	}
	if wedge.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(wedge.Number)})
	}
	return WriteObject(w, name, attrs)
}

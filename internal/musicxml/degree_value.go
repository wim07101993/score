package musicxml

import (
	"encoding/xml"
	"strconv"
)

type DegreeValue struct {
	Value  int
	Symbol string
	Text   string
}

func readDegreeValue(r xml.TokenReader, element xml.StartElement) (value *DegreeValue, err error) {
	value = &DegreeValue{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "text":
			value.Text = attr.Value
		case "symbol":
			value.Symbol = attr.Value
		default:
			return value, &UnknownAttribute{element, attr}
		}
	}

	value.Value, err = ReadInt(r, element)

	return value, err
}

func writeDegreeValue(w *xml.Encoder, name string, value *DegreeValue) (err error) {
	def := DegreeValue{}
	var attrs []xml.Attr
	if value.Symbol != def.Symbol {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "symbol"}, Value: value.Symbol})
	}
	if value.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: value.Text})
	}
	return WriteString(w, name, strconv.Itoa(value.Value), attrs)
}

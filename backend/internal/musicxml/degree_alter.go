package musicxml

import (
	"encoding/xml"
	"fmt"
)

type DegreeAlter struct {
	Value     float32
	PlusMinus bool
}

func readDegreeAlter(r xml.TokenReader, element xml.StartElement) (alter *DegreeAlter, err error) {
	alter = &DegreeAlter{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "plus-minus":
			alter.PlusMinus = attr.Value == "yes"
		default:
			return alter, &UnknownAttribute{element, attr}
		}
	}

	alter.Value, err = ReadFloat32(r, element)

	return alter, err
}

func writeDegreeAlter(w *xml.Encoder, name string, alter *DegreeAlter) (err error) {
	var attrs []xml.Attr
	if alter.PlusMinus {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "plus-minus"}, Value: "yes"})
	}
	return WriteString(w, name, fmt.Sprintf("%g", alter.Value), attrs)
}

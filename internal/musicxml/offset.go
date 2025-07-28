package musicxml

import (
	"encoding/xml"
	"fmt"
)

type Offset struct {
	Divisions float32
	Sound     bool
}

func readOffset(r xml.TokenReader, element xml.StartElement) (offset *Offset, err error) {
	offset = &Offset{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "sound":
			offset.Sound = attr.Value == "yes"
		default:
			return offset, &UnknownAttribute{element, attr}
		}
	}

	offset.Divisions, err = ReadFloat32(r, element)
	return offset, err
}

func writeOffset(w *xml.Encoder, name string, offset *Offset) (err error) {
	var attrs []xml.Attr
	if offset.Sound {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "sound"}, Value: "yes"})
	}
	return WriteString(w, name, fmt.Sprintf("%g", offset.Divisions), attrs)
}

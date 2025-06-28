package musicxml

import "encoding/xml"

type Fingering struct {
	Value        string
	Substitution bool
	Alternate    bool
}

func readFingering(r xml.TokenReader, element xml.StartElement) (f *Fingering, err error) {
	f = &Fingering{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "substitution":
			f.Substitution = attr.Value == "yes"
		case "alternate":
			f.Alternate = attr.Value == "yes"
		default:
			return f, &UnknownAttribute{element, attr}
		}
	}

	f.Value, err = ReadString(r, element)
	return f, err
}

func writeFingering(w *xml.Encoder, name string, fingering *Fingering) (err error) {
	var attrs []xml.Attr
	if fingering.Substitution {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "substitution"}, Value: "yes"})
	}
	if fingering.Alternate {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "alternate"}, Value: "yes"})
	}
	return WriteString(w, name, fingering.Value, nil)
}

package musicxml

import "encoding/xml"

type Fermata struct {
	Shape      string
	IsInverted bool
}

func readFermata(r xml.TokenReader, element xml.StartElement) (fermata *Fermata, err error) {
	fermata = &Fermata{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "type":
			fermata.IsInverted = attr.Value == "inverted"
		default:
			return fermata, &UnknownAttribute{element, attr}
		}
	}

	val, err := ReadString(r, element)
	fermata.Shape = val

	return fermata, err
}

func writeFermata(w *xml.Encoder, name string, fermata *Fermata) (err error) {
	var attrs []xml.Attr
	if fermata.IsInverted {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "type"}, Value: "inverted"})
	}

	return WriteString(w, name, fermata.Shape, attrs)
}

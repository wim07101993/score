package musicxml

import "encoding/xml"

type DegreeType struct {
	Value string
	Text  string
}

func readDegreeType(r xml.TokenReader, element xml.StartElement) (tp *DegreeType, err error) {
	tp = &DegreeType{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "text":
			tp.Text = attr.Value
		default:
			return tp, &UnknownAttribute{element, attr}
		}
	}

	tp.Value, err = ReadString(r, element)

	return tp, err
}

func writeDegreeType(w *xml.Encoder, name string, tp *DegreeType) (err error) {
	def := DegreeType{}
	var attrs []xml.Attr
	if tp.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: tp.Text})
	}
	return WriteString(w, name, tp.Value, attrs)
}

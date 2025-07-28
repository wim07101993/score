package musicxml

import (
	"encoding/xml"
	"strconv"
)

type FirstFret struct {
	Value    int
	Text     string
	Location string
}

func readFirstFret(r xml.TokenReader, element xml.StartElement) (fret *FirstFret, err error) {
	fret = &FirstFret{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "text":
			fret.Text = attr.Value
		case "location":
			fret.Location = attr.Value
		default:
			return fret, &UnknownAttribute{element, attr}
		}
	}

	fret.Value, err = ReadInt(r, element)
	return fret, err
}

func writeFirstFret(w *xml.Encoder, name string, fret *FirstFret) (err error) {
	def := FirstFret{}
	var attrs []xml.Attr
	if fret.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: fret.Text})
	}
	if fret.Location != def.Location {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "location"}, Value: fret.Location})
	}

	return WriteString(w, name, strconv.Itoa(fret.Value), attrs)
}

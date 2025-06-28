package musicxml

import "encoding/xml"

type Accidental struct {
	Value string
}

func readAccidental(r xml.TokenReader, element xml.StartElement) (acc *Accidental, err error) {
	acc = &Accidental{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		default:
			return acc, &UnknownAttribute{element, attr}
		}
	}

	acc.Value, err = ReadString(r, element)
	return acc, err
}

func writeAccidental(w *xml.Encoder, name string, accidental *Accidental) (err error) {
	return WriteString(w, name, accidental.Value, nil)
}

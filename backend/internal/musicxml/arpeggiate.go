package musicxml

import "encoding/xml"

type Arpeggiate struct {
}

func readArpeggiate(r xml.TokenReader, element xml.StartElement) (apr *Arpeggiate, err error) {
	apr = &Arpeggiate{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return apr, err
}

func writeArpeggiate(w *xml.Encoder, name string, _ *Arpeggiate) (err error) {
	return WriteObject(w, name, nil)
}

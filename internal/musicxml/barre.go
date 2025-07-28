package musicxml

import "encoding/xml"

type Barre struct {
	Type string
}

func readBarre(r xml.TokenReader, element xml.StartElement) (barre *Barre, err error) {
	barre = &Barre{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				barre.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})

	return barre, err
}

func writeBarre(w *xml.Encoder, name string, barre *Barre) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "type"}, Value: barre.Type}})
}

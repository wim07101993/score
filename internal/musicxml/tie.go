package musicxml

import "encoding/xml"

type Tie struct {
	Type string
}

func readTie(r xml.TokenReader, element xml.StartElement) (tie *Tie, err error) {
	tie = &Tie{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				tie.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return tie, err
}

func writeTie(w *xml.Encoder, name string, tie *Tie) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "type"}, Value: tie.Type}})
}

package musicxml

import "encoding/xml"

type Pedal struct {
	Type   string
	Number int
	Line   bool
}

func pedal(r xml.TokenReader, element xml.StartElement) (p *Pedal, err error) {
	p = &Pedal{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				p.Type = attr.Value
			case "line":
				p.Line = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return p, err
}

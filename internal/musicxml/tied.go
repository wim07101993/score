package musicxml

import "encoding/xml"

type Tied struct {
	Type        string
	Orientation string
}

func readTied(r xml.TokenReader, element xml.StartElement) (tied *Tied, err error) {
	tied = &Tied{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "orientation":
				tied.Orientation = attr.Value
			case "type":
				tied.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return tied, err
}

func writeTied(w *xml.Encoder, name string, tied *Tied) (err error) {
	def := Tied{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: tied.Type},
	}
	if tied.Orientation != def.Orientation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "orientation"}, Value: tied.Orientation})
	}
	return WriteObject(w, name, attrs)
}

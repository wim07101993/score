package musicxml

import "encoding/xml"

type Repeat struct {
	Direction string
}

func readRepeat(r xml.TokenReader, element xml.StartElement) (repeat *Repeat, err error) {
	repeat = &Repeat{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "direction":
				repeat.Direction = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return repeat, err
}

func writeRepeat(w *xml.Encoder, name string, repeat *Repeat) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "direction"}, Value: repeat.Direction},
	})
}

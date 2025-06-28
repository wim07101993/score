package musicxml

import "encoding/xml"

type Ending struct {
	Number string
	Type   string
}

func readEnding(r xml.TokenReader, element xml.StartElement) (ending *Ending, err error) {
	ending = &Ending{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				ending.Number = attr.Value
			case "type":
				ending.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return ending, err
}

func writeEnding(w *xml.Encoder, name string, ending *Ending) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "number"}, Value: ending.Number},
		{Name: xml.Name{Local: "type"}, Value: ending.Type},
	})
}

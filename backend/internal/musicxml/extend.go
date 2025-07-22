package musicxml

import "encoding/xml"

type Extend struct {
	Type string
}

func readExtend(r xml.TokenReader, element xml.StartElement) (extend *Extend, err error) {
	extend = &Extend{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				extend.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {

			return &UnknownElement{element, el}
		})
	return extend, err
}

func writeExtend(w *xml.Encoder, name string, extend *Extend) (err error) {
	var attrs []xml.Attr
	if extend.Type != "" {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "type"}, Value: extend.Type})
	}
	return WriteObject(w, name, attrs)
}

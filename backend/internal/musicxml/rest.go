package musicxml

import "encoding/xml"

type Rest struct {
	Measure bool
}

func readRest(r xml.TokenReader, element xml.StartElement) (rest *Rest, err error) {
	rest = &Rest{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "measure":
				rest.Measure = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return rest, err
}

func writeRest(w *xml.Encoder, name string, rest *Rest) (err error) {
	var attrs []xml.Attr
	if rest.Measure {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "measure"}, Value: "yes"})
	}
	return WriteObject(w, name, attrs)
}

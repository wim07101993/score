package musicxml

import "encoding/xml"

type Grace struct {
	Slash bool
}

func readGrace(r xml.TokenReader, element xml.StartElement) (grace *Grace, err error) {
	grace = &Grace{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "slash":
				grace.Slash = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return grace, err
}

func writeGrace(w *xml.Encoder, name string, grace *Grace) (err error) {
	var attrs []xml.Attr
	if grace.Slash {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "slash"}, Value: "yes"})
	}
	return WriteObject(w, name, attrs)
}

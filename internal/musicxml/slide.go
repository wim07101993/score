package musicxml

import "encoding/xml"

type Slide struct {
	Type string
}

func readSlide(r xml.TokenReader, element xml.StartElement) (slide *Slide, err error) {
	slide = &Slide{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				slide.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return slide, err
}

func writeSlide(w *xml.Encoder, name string, slide *Slide) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: slide.Type},
	})
}

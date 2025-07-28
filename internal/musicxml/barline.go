package musicxml

import "encoding/xml"

type Barline struct {
	Location string
	Style    string
	Repeat   *Repeat
	Ending   *Ending
}

func readBarline(r xml.TokenReader, element xml.StartElement) (barline *Barline, err error) {
	barline = &Barline{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "location":
				barline.Location = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "bar-style":
				if barline.Style != "" {
					return &FieldAlreadySet{element, el}
				}
				barline.Style, err = ReadString(r, el)
			case "ending":
				if barline.Ending != nil {
					return &FieldAlreadySet{element, el}
				}
				barline.Ending, err = readEnding(r, el)
			case "repeat":
				if barline.Repeat != nil {
					return &FieldAlreadySet{element, el}
				}
				barline.Repeat, err = readRepeat(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return barline, err
}

func writeBarline(w *xml.Encoder, name string, barline *Barline) (err error) {
	def := Barline{}
	var attrs []xml.Attr
	if barline.Location != def.Location {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "location"}, Value: barline.Location})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if barline.Style != def.Style {
				return WriteString(w, "bar-style", barline.Style, nil)
			}
			return nil
		},
		func() error {
			if barline.Ending != nil {
				return writeEnding(w, "ending", barline.Ending)
			}
			return nil
		},
		func() error {
			if barline.Repeat != nil {
				return writeRepeat(w, "repeat", barline.Repeat)
			}
			return nil
		},
	)
}

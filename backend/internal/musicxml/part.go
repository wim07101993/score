package musicxml

import "encoding/xml"

type Part struct {
	Id string
	// Measures is a list of all the measures of this part.
	// The order of this list is important.
	Measures []*Measure
}

func readPart(r xml.TokenReader, element xml.StartElement) (part *Part, err error) {
	part = &Part{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				part.Id = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "measure":
				measure, err := readMeasure(r, el)
				if err != nil {
					return err
				}
				part.Measures = append(part.Measures, measure)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return part, err
}

func writePart(w *xml.Encoder, name string, part *Part) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "id"}, Value: part.Id},
		},
		func() error {
			for _, measure := range part.Measures {
				if err = writeMeasure(w, "measure", measure); err != nil {
					return err
				}
			}
			return nil
		})
}

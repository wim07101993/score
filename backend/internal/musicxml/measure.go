package musicxml

import "encoding/xml"

type Measure struct {
	Number   string
	Elements []MeasureElement
}

func readMeasure(r xml.TokenReader, element xml.StartElement) (measure *Measure, err error) {
	measure = &Measure{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				measure.Number = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			var item MeasureElement
			switch el.Name.Local {
			case "attributes":
				item.Attributes, err = readMeasureAttributes(r, el)
			case "print":
				err = ReadUntilClose(r, el)
			case "direction":
				item.Direction, err = readDirection(r, el)
			case "note":
				item.Note, err = readNote(r, el)
			case "barline":
				item.Barline, err = readBarline(r, el)
			case "harmony":
				item.Harmony, err = readHarmony(r, el)
			case "backup":
				item.Backup, err = readBackup(r, el)
			case "forward":
				item.Forward, err = readForward(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			if err != nil {
				return err
			}
			measure.Elements = append(measure.Elements, item)
			return nil
		})

	return measure, err
}
func writeMeasure(w *xml.Encoder, name string, measure *Measure) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "number"}, Value: measure.Number},
		},
		func() error {
			for _, element := range measure.Elements {
				if element.Attributes != nil {
					if err = writeMeasureAttributes(w, "attributes", element.Attributes); err != nil {
						return err
					}
				}
				if element.Backup != nil {
					if err = writeBackup(w, "backup", element.Backup); err != nil {
						return err
					}
				}
				if element.Direction != nil {
					if err = writeDirection(w, "direction", element.Direction); err != nil {
						return err
					}
				}
				if element.Forward != nil {
					if err = writeForward(w, "forward", element.Forward); err != nil {
						return err
					}
				}
				if element.Harmony != nil {
					if err = writeHarmony(w, "harmony", element.Harmony); err != nil {
						return err
					}
				}
				if element.Barline != nil {
					if err = writeBarline(w, "barline", element.Barline); err != nil {
						return err
					}
				}
				if element.Note != nil {
					if err = writeNote(w, "note", element.Note); err != nil {
						return nil
					}
				}
			}
			return nil
		})
}

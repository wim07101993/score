package musicxml

import "encoding/xml"

type Work struct {
	Title  string
	Number string
}

func readWork(r xml.TokenReader, element xml.StartElement) (work *Work, err error) {
	work = &Work{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "work-title":
				if work.Title != "" {
					return &FieldAlreadySet{element, el}
				}
				work.Title, err = ReadString(r, el)
			case "work-number":
				if work.Number != "" {
					return &FieldAlreadySet{element, el}
				}
				work.Number, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return work, err
}

func writeWork(w *xml.Encoder, name string, work *Work) (err error) {
	def := Work{}
	return WriteObject(w, name, nil,
		func() error {
			if work.Title == def.Title {
				return nil
			}
			return WriteString(w, "work-title", work.Title, nil)
		},
		func() error {
			if work.Number == def.Number {
				return nil
			}
			return WriteString(w, "work-number", work.Number, nil)
		})
}

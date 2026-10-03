package musicxml

import "encoding/xml"

type Work struct {
	Title  string
	Number string
}

func readWork(r xml.TokenReader, element xml.StartElement) (work *Work, err error) {
	work = &Work{}
	err = ReadObject(r, element,
		// None of its attributes are needed; see ReadObject.
		nil,
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
				// Not needed here; see ReadObject.
				err = ReadUntilClose(r, el)
			}
			return err
		})
	return work, err
}

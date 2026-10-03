package musicxml

import (
	"encoding/xml"
	"time"
)

type Encoding struct {
	Date time.Time
}

func readEncoding(r xml.TokenReader, element xml.StartElement) (encoding *Encoding, err error) {
	encoding = &Encoding{}
	err = ReadObject(r, element,
		// None of its attributes are needed; see ReadObject.
		nil,
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "encoding-date":
				if !encoding.Date.Equal(time.Time{}) {
					return &FieldAlreadySet{element, el}
				}
				encoding.Date, err = ReadTime(r, el)
			case "encoder", "software", "encoding-description", "supports":
				err = ReadUntilClose(r, el) // IGNORE from which software the xml was written
			default:
				// Not needed here; see ReadObject.
				err = ReadUntilClose(r, el)
			}
			return err
		})
	return encoding, err
}

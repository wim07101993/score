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
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
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
				err = &UnknownElement{element, el}
			}
			return err
		})
	return encoding, err
}

func writeEncoding(w *xml.Encoder, name string) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "encoding-date", time.Now().UTC().Format("2006-01-02"), nil)
		})
}

package musicxml

import (
	"encoding/xml"
	"fmt"
)

type Backup struct {
	Duration float32
}

func readBackup(r xml.TokenReader, element xml.StartElement) (backup *Backup, err error) {
	backup = &Backup{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "duration":
				if backup.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				backup.Duration, err = ReadFloat32(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return backup, err
}

func writeBackup(w *xml.Encoder, name string, backup *Backup) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "duration", fmt.Sprintf("%g", backup.Duration), nil)
		})
}

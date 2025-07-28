package musicxml

import (
	"encoding/xml"
	"strconv"
)

type KeyMode string

type Fifths int

type Key struct {
	Fifths Fifths
	Mode   string
}

func readKey(r xml.TokenReader, element xml.StartElement) (key *Key, err error) {
	key = &Key{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "fifths":
				if key.Fifths != 0 {
					return &FieldAlreadySet{element, el}
				}
				i, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				key.Fifths = Fifths(i)
			case "mode":
				if key.Mode != "" {
					return &FieldAlreadySet{element, el}
				}
				key.Mode, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return key, err
}

func writeKey(w *xml.Encoder, name string, key *Key) (err error) {
	def := Key{}
	return WriteObject(w, name,
		nil,
		func() error {
			return WriteString(w, "fifths", strconv.Itoa(int(key.Fifths)), nil)
		},
		func() error {
			if key.Mode != def.Mode {
				return WriteString(w, "mode", key.Mode, nil)
			}
			return nil
		},
	)
}

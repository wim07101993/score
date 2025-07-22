package musicxml

import (
	"encoding/xml"
	"fmt"
)

type Forward struct {
	Duration float32
	Voice    string
	Staff    int
}

func readForward(r xml.TokenReader, element xml.StartElement) (forward *Forward, err error) {
	forward = &Forward{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "duration":
				if forward.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				forward.Duration, err = ReadFloat32(r, el)
			case "voice":
				if forward.Voice != "" {
					return &FieldAlreadySet{element, el}
				}
				forward.Voice, err = ReadString(r, el)
			case "staff":
				if forward.Staff != 0 {
					return &FieldAlreadySet{element, el}
				}
				forward.Staff, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return forward, err
}

func writeForward(w *xml.Encoder, name string, forward *Forward) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "duration", fmt.Sprintf("%g", forward.Duration), nil)
		})
}

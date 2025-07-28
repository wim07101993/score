package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Technical struct {
	Fret   int
	String int
}

func readTechnical(r xml.TokenReader, element xml.StartElement) (tech *Technical, err error) {
	tech = &Technical{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "fret":
				if tech.Fret != 0 {
					return &FieldAlreadySet{element, el}
				}
				tech.Fret, err = ReadInt(r, el)
			case "string":
				if tech.String != 0 {
					return &FieldAlreadySet{element, el}
				}
				tech.String, err = ReadInt(r, el)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tech, err
}

func writeTechnical(w *xml.Encoder, name string, technical *Technical) (err error) {
	def := Technical{}
	return WriteObject(w, name, nil,
		func() error {
			if technical.Fret != def.Fret {
				if err = WriteString(w, "fret", strconv.Itoa(technical.Fret), nil); err != nil {
					return err
				}
			}
			if technical.String != def.String {
				if err = WriteString(w, "string", strconv.Itoa(technical.String), nil); err != nil {
					return err
				}
			}
			return nil
		})
}

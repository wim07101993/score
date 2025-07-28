package musicxml

import (
	"encoding/xml"
	"strconv"
)

type TupletPortion struct {
	Number   int
	Type     string
	DotCount int
}

func readTupletPortion(r xml.TokenReader, element xml.StartElement) (portion *TupletPortion, err error) {
	portion = &TupletPortion{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuplet-number":
				if portion.Number != 0 {
					return &FieldAlreadySet{element, el}
				}
				portion.Number, err = ReadInt(r, el)
			case "tuplet-type":
				if portion.Type != "" {
					return &FieldAlreadySet{element, el}
				}
				portion.Type, err = ReadString(r, el)
			case "tuplet-dot":
				err = ReadUntilClose(r, el)
				portion.DotCount++
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return portion, err
}

func writeTupletPortion(w *xml.Encoder, name string, tuplet *TupletPortion) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "tuplet-number", strconv.Itoa(tuplet.Number), nil)
		},
		func() error {
			return WriteString(w, "tuplet-type", tuplet.Type, nil)
		},
		func() error {
			for i := 0; i < tuplet.Number; i++ {
				if err = WriteObject(w, "tuplet-dot", nil); err != nil {
					return err
				}
			}
			return nil
		})
}

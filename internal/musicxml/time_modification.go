package musicxml

import (
	"encoding/xml"
	"strconv"
)

type TimeModification struct {
	ActualNotes int
	NormalNotes int
	Items       []TimeModificationItem
}

func readTimeModification(r xml.TokenReader, element xml.StartElement) (mod *TimeModification, err error) {
	mod = &TimeModification{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "actual-notes":
				if mod.ActualNotes != 0 {
					return &FieldAlreadySet{element, el}
				}
				mod.ActualNotes, err = ReadInt(r, el)
			case "normal-notes":
				if mod.NormalNotes != 0 {
					return &FieldAlreadySet{element, el}
				}
				mod.NormalNotes, err = ReadInt(r, el)
			case "normal-type":
				tp, err := ReadString(r, el)
				if err != nil {
					return err
				}
				mod.Items = append(mod.Items, TimeModificationItem{NormalType: tp})
			case "normal-dot":
				err = ReadUntilClose(r, el)
				mod.Items = append(mod.Items, TimeModificationItem{HasDot: true})
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return mod, err
}

func writeTimeModification(w *xml.Encoder, name string, time *TimeModification) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "actual-notes", strconv.Itoa(time.ActualNotes), nil)
		},
		func() error {
			return WriteString(w, "normal-notes", strconv.Itoa(time.NormalNotes), nil)
		},
		func() error {
			def := TimeModificationItem{}
			for _, item := range time.Items {
				if item.NormalType != def.NormalType {
					if err = WriteString(w, "normal-type", item.NormalType, nil); err != nil {
						return err
					}
				}
				if item.HasDot {
					if err = WriteObject(w, "normal-dot", nil); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

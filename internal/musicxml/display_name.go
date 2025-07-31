package musicxml

import (
	"encoding/xml"
	"strings"
)

type DisplayName struct {
	Items []DisplayNameItem
}

func (name DisplayName) String() string {
	switch len(name.Items) {
	case 0:
		return ""
	case 1:
		return name.Items[0].DisplayText + name.Items[0].AccidentalText
	}

	b := strings.Builder{}
	for _, item := range name.Items {
		if len(item.DisplayText) != 0 {
			b.WriteString(item.DisplayText)
		}
		if len(item.AccidentalText) != 0 {
			b.WriteString(item.AccidentalText)
		}
	}
	return b.String()
}

func readDisplayName(r xml.TokenReader, element xml.StartElement) (name *DisplayName, err error) {
	name = &DisplayName{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "display-text":
				text, err := ReadString(r, el)
				if err != nil {
					return err
				}
				name.Items = append(name.Items, DisplayNameItem{DisplayText: text})
			case "accidental-text":
				text, err := ReadString(r, el)
				if err != nil {
					return err
				}
				name.Items = append(name.Items, DisplayNameItem{AccidentalText: text})
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	if len(name.Items) == 0 {
		return nil, err
	}
	return name, err
}

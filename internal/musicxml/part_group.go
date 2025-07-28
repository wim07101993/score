package musicxml

import (
	"encoding/xml"
	"strconv"
)

const (
	PartGroupType_Start = "start"
	PartGroupType_Stop  = "stop"
)

type PartGroup struct {
	Type   string
	Number int
	Symbol string
}

func readPartGroup(r xml.TokenReader, element xml.StartElement) (group *PartGroup, err error) {
	group = &PartGroup{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				group.Type = attr.Value
			case "number":
				group.Number, err = strconv.Atoi(attr.Value)
			default:
				err = &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "group-symbol":
				group.Symbol, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return group, err
}

func writePartGroup(w *xml.Encoder, name string, group *PartGroup) (err error) {
	def := PartGroup{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "type"}, Value: group.Type},
			{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(group.Number)},
		},
		func() error {
			if group.Symbol != def.Symbol {
				return WriteString(w, "group-symbol", group.Symbol, nil)
			}
			return nil
		})
}

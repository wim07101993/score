package musicxml

import "encoding/xml"

type PartListItem struct {
	PartGroup *PartGroup
	ScorePart *ScorePart
}

func readPartList(r xml.TokenReader, element xml.StartElement) (list []PartListItem, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			var item PartListItem
			switch el.Name.Local {
			case "part-group":
				item.PartGroup, err = readPartGroup(r, el)
			case "score-part":
				item.ScorePart, err = readScorePart(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			if err == nil {
				list = append(list, item)
			}
			return err
		})
	return list, err
}

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

func writePartList(w *xml.Encoder, name string, partList []PartListItem) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, item := range partList {
				if item.PartGroup != nil {
					if err = writePartGroup(w, "part-group", item.PartGroup); err != nil {
						return err
					}
				}
				if item.ScorePart != nil {
					if err = writeScorePart(w, "score-part", item.ScorePart); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

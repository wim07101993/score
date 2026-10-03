package musicxml

import "encoding/xml"

type PartListItem struct {
	PartGroup *PartGroup
	ScorePart *ScorePart
}

func readPartList(r xml.TokenReader, element xml.StartElement) (list []PartListItem, err error) {
	err = ReadObject(r, element,
		// None of its attributes are needed; see ReadObject.
		nil,
		func(el xml.StartElement) error {
			var item PartListItem
			switch el.Name.Local {
			case "part-group":
				item.PartGroup, err = readPartGroup(r, el)
			case "score-part":
				item.ScorePart, err = readScorePart(r, el)
			default:
				// Not needed here; see ReadObject.
				err = ReadUntilClose(r, el)
			}
			// An element that was skipped is not an item: it would turn up as
			// one that is neither a group nor a part.
			if err == nil && (item.PartGroup != nil || item.ScorePart != nil) {
				list = append(list, item)
			}
			return err
		})
	return list, err
}

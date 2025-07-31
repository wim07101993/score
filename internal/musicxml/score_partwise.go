package musicxml

import (
	"encoding/xml"
	"fmt"
)

type ScorePartwise struct {
	Work           *Work
	Identification *Identification
	Defaults       *Defaults
	PartList       []PartListItem
	MovementNumber string
	MovementTitle  string
}

func scorePartwise(r xml.TokenReader, element xml.StartElement) (score *ScorePartwise, err error) {
	score = &ScorePartwise{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "version":
				if attr.Value != "4.0" && attr.Value != "3.0" && attr.Value != "3.1" {
					return fmt.Errorf("expected musicxml version 4.0, 3.1 or 3.0")
				}
				return nil
			default:
				return &UnknownAttribute{element, attr}
			}
		},
		func(el xml.StartElement) (err error) {
			switch el.Name.Local {
			case "work":
				if score.Work != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Work, err = readWork(r, el)
			case "movement-number":
				if score.MovementNumber != "" {
					return &FieldAlreadySet{element, el}
				}
				score.MovementNumber, err = ReadString(r, el)
			case "movement-title":
				if score.MovementTitle != "" {
					return &FieldAlreadySet{element, el}
				}
				score.MovementTitle, err = ReadString(r, el)
			case "identification":
				if score.Identification != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Identification, err = readIdentification(r, el)
			case "defaults":
				if score.Defaults != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Defaults, err = readDefaults(r, el)
			case "credit":
				err = ReadUntilClose(r, el) // IGNORE credits
			case "part-list":
				if score.PartList != nil {
					return &FieldAlreadySet{element, el}
				}
				score.PartList, err = readPartList(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return score, err
}

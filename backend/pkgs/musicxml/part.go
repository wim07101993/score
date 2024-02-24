package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
)

func (p *Parser) parsePart(start xml.StartElement, score *models.Score) error {
	var part *models.Part
	return p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				part = score.Parts.Part(attr.Value)
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "measure":
				m, err := p.parseMeasure(el)
				if err != nil {
					return err
				}
				if part == nil {
					return fmt.Errorf("unknown part (%v)", start)
				}
				part.Measures = append(part.Measures, m)
				return nil
			default:
				p.unknownElement(start, el)
				return p.ignoreObject(el)
			}
		})
}

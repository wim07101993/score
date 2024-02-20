package musicxml

import (
	"encoding/xml"
	"score/backend/pkgs/models"
)

func (p *Parser) parseWorkElementsIntoScore(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "work-title":
			score.Title, err = p.CharData(r)
		default:
			err = p.unknownElement(r, root, el)
		}
		return err
	})
}

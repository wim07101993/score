package musicxml

import (
	"encoding/xml"
	"score/backend/pkgs/models"
)

func (p *Parser) parseWorkElementsIntoScore(start xml.StartElement, score *models.Score) error {
	return p.readObject(start, nil, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "work-title":
			score.Title, err = p.readString(el)
		default:
			p.unknownElement(start, el)
			err = p.ignoreObject(el)
		}
		return err
	})
}

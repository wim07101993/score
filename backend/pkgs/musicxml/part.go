package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
)

func (p *Parser) parsePart(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	var part *models.Part
	for _, attr := range root.Attr {
		switch attr.Name.Local {
		case "id":
			part = score.Parts.Part(attr.Value)
		default:
			p.unknownAttribute(root, attr)
		}
	}

	if part == nil {
		return fmt.Errorf("unknown part (%v)", root)
	}

	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "measure":
			var m *models.Measure
			m, err := p.parseMeasure(r, root)
			if err == nil {
				part.Measures = append(part.Measures, m)
			}
		default:
			err = p.unknownElement(r, root, el)
		}
		return err
	})
}

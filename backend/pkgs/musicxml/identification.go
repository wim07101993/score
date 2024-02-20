package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
)

func (p *Parser) parseIdentificationIntoScore(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "creator":
			return p.parseCreatorIntoScore(r, el, score)
		default:
			return p.unknownElement(r, root, el)
		}
	})
}

func (p *Parser) parseCreatorIntoScore(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	t, err := r.Token()
	if err != nil {
		return err
	}

	var val string
	switch el := t.(type) {
	case xml.CharData:
		val = string(el)
	default:
		p.unknownToken(root, t)
		fmt.Printf("unknown token for 'creator': %v\n", el)
	}

	if val == "" {
		return nil
	}

	for _, attr := range root.Attr {
		switch attr.Name.Local {
		case "type":
			switch attr.Value {
			case "composer":
				score.Composers = append(score.Composers, attr.Value)
			case "lyricist":
				score.Lyricists = append(score.Lyricists, attr.Value)
			default:
				fmt.Printf("unknown type of creator %v\n", attr.Value)
			}
		default:
			fmt.Printf("unknown creator attribute %v\n", attr)
		}
	}
	return nil
}

package musicxml

import (
	"encoding/xml"
	"log/slog"
	"score/backend/pkgs/models"
)

func (p *Parser) parseIdentificationIntoScore(start xml.StartElement, score *models.Score) error {
	return p.readObject(start, nil, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "creator":
			return p.parseCreatorIntoScore(el, score)
		default:
			p.unknownElement(start, el)
			return p.ignoreObject(el)
		}
	})
}

func (p *Parser) parseCreatorIntoScore(start xml.StartElement, score *models.Score) error {
	t, err := p.Reader.Token()
	if err != nil {
		return err
	}

	var val string
	switch el := t.(type) {
	case xml.CharData:
		val = string(el)
	default:
		p.unexpectedToken(start, t)
	}

	err = p.readUntilClose(start)
	if err != nil {
		return err
	}

	if val == "" {
		return nil
	}

	for _, attr := range start.Attr {
		switch attr.Name.Local {
		case "type":
			switch attr.Value {
			case "composer":
				score.Composers = append(score.Composers, val)
			case "lyricist":
				score.Lyricists = append(score.Lyricists, val)
			default:
				p.Logger.Warn("unknown type of creator", slog.Any("creator", attr.Value))
			}
		default:
			p.unknownAttribute(start, attr)
		}
	}
	return nil
}

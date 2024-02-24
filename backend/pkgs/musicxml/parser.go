package musicxml

import (
	"encoding/xml"
	"log/slog"
	"score/backend/pkgs/models"
	"strings"
)

type Parser struct {
	Reader xml.TokenReader
	logger *slog.Logger
}

func NewParser(reader xml.TokenReader, logger *slog.Logger) *Parser {
	return &Parser{
		Reader: reader,
		logger: logger,
	}
}

func (p *Parser) FromXml() (*models.Score, error) {
	root := xml.StartElement{
		Name: xml.Name{Local: "root"},
	}
	var score *models.Score
	err := p.readObject(root, nil, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "score-partwise":
			score, err = p.parseScorePartwise(el)
		default:
			p.unknownElement(root, el)
			err = p.ignoreObject(el)
		}
		return err
	})
	return score, err
}

func (p *Parser) parseScorePartwise(start xml.StartElement) (*models.Score, error) {
	score := &models.Score{}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "version":
			// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "work":
				return p.parseWorkElementsIntoScore(el, score)
			case "identification":
				return p.parseIdentificationIntoScore(el, score)
			case "part-list":
				var err error
				score.Parts, err = p.parsePartList(el)
				return err
			case "part":
				return p.parsePart(el, score)
			default:
				p.unknownElement(start, el)
				return p.ignoreObject(el)
			}
		})
	return score, err
}

func (p *Parser) parseDisplayText(start xml.StartElement) (string, error) {
	text := strings.Builder{}
	err := p.readObject(start, nil, func(el xml.StartElement) error {
		var err error
		var s string
		switch el.Name.Local {
		case "display-text":
			s, err = p.readString(el)
			text.WriteString(s)
		case "accidental-text":
			s, err = p.readString(el)
			text.WriteString(p.AccidentalToString(s))
		default:
			p.unknownElement(start, el)
			return p.ignoreObject(el)
		}
		return err
	})
	return text.String(), err
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"io"
	"score/backend/pkgs/models"
	"strings"
)

type Parser struct {
}

func (p *Parser) FromXml(r xml.TokenReader) (*models.Score, error) {
	root := xml.StartElement{
		Name: xml.Name{Local: "root"},
	}
	var score *models.Score
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "score-partwise":
			score, err = p.parseScorePartwise(r, el)
		default:
			p.unknownElement(root, el)
		}
		return err
	})
	if err != nil {
		return nil, err
	}
	return score, nil
}

func (p *Parser) parseScorePartwise(r xml.TokenReader, root xml.StartElement) (*models.Score, error) {
	score := &models.Score{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "work":
			return p.parseWorkElementsIntoScore(r, el, score)
		case "identification":
			return p.parseIdentificationIntoScore(r, el, score)
		case "part-list":
			var err error
			score.PartGroup, err = p.parsePartList(r, el)
			return err
		case "part":
			return p.parsePart(r, score)
		default:
			p.unknownElement(root, el)
			return nil
		}
	})
	return score, err
}

func (p *Parser) parseWorkElementsIntoScore(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "work-title":
			score.Title, err = p.CharData(r)
		default:
			p.unknownElement(root, el)
		}
		return err
	})
}

func (p *Parser) parseIdentificationIntoScore(r xml.TokenReader, root xml.StartElement, score *models.Score) error {
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "creator":
			return p.parseCreatorIntoScore(r, el, score)
		default:
			p.unknownElement(root, el)
			return nil
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

func (p *Parser) parsePartList(r xml.TokenReader, root xml.StartElement) (*models.PartGroup, error) {
	ret := &models.PartGroup{}
	open := []*models.PartGroup{ret}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "part-group":
			var tp string
			var id string
			for _, attr := range el.Attr {
				switch attr.Name.Local {
				case "type":
					tp = attr.Value
				case "number":
					id = attr.Value
				default:
					p.unknownAttribute(el, attr)
				}
			}

			switch tp {
			case "start":
				pg, err := p.parsePartGroup(r, el, id)
				if err != nil {
					return err
				}
				open = append(open, pg)
				if len(open) == 0 {
					ret.PartGroups = append(ret.PartGroups)
				} else {
					parent := open[len(open)-1]
					parent.PartGroups = append(parent.PartGroups, pg)
				}
			case "stop":
				for i := range open {
					if open[i].Id == id {
						copy(open[i:], open[i+1:])
						open = open[:len(open)-1]
						break
					}
				}
			}

			return nil

		case "score-part":
			part, err := p.parseScorePart(r, el)
			if err != nil {
				return err
			}
			pg := open[len(open)-1]
			pg.Parts = append(pg.Parts, part)
			return nil
		default:
			p.unknownElement(root, el)
			return nil
		}
	})
	return ret, err
}

func (p *Parser) parsePartGroup(r xml.TokenReader, root xml.StartElement, id string) (*models.PartGroup, error) {
	pg := &models.PartGroup{Id: id}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "group-symbol":
			pg.Symbol, err = p.CharData(r)
		default:
			p.unknownElement(root, el)
		}
		return err
	})
	return pg, err
}

func (p *Parser) parseScorePart(r xml.TokenReader, root xml.StartElement) (*models.Part, error) {
	var id string
	for _, attr := range root.Attr {
		switch attr.Name.Local {
		case "id":
			id = attr.Value
		default:
			p.unknownAttribute(root, attr)
		}
	}

	part := &models.Part{Id: id}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "part-name":
			part.Name, err = p.CharData(r)
		case "part-name-display":
			part.NameDisplay, err = p.parseDisplayText(r, el)
		case "part-abbreviation":
			part.Name, err = p.CharData(r)
		case "part-abbreviation-display":
			part.AbbreviationDisplay, err = p.parseDisplayText(r, el)
		case "score-instrument":
			part.Instrument, err = p.parseInstrument(r, el)
		default:
			p.unknownElement(root, el)
		}
		return err
	})
	return part, err
}

func (p *Parser) parseInstrument(r xml.TokenReader, root xml.StartElement) (string, error) {
	var instrument string
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "instrument-name":
			instrument, err = p.CharData(r)
		default:
			p.unknownElement(root, el)
		}
		return err
	})
	return instrument, err
}

func (p *Parser) parseDisplayText(r xml.TokenReader, root xml.StartElement) (string, error) {
	display := strings.Builder{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		var s string
		switch el.Name.Local {
		case "display-text":
			s, err = p.CharData(r)
			display.WriteString(s)
		case "accidental-text":
			s, err = p.CharData(r)
			display.WriteString(AccidentalToString(s))
		default:
			p.unknownElement(root, el)
		}
		return err
	})
	return display.String(), err
}

func (p *Parser) parsePart(r xml.TokenReader, score *models.Score) error {
	fmt.Println("TODO parse part")
	return nil
}

func (p *Parser) unknownElement(root xml.StartElement, el xml.StartElement) {
	fmt.Printf("unknown element %v for %v\n", el.Name.Local, root.Name.Local)
}

func (p *Parser) unknownToken(root xml.StartElement, t xml.Token) {
	fmt.Printf("unexpected token %v for %v\n", t, root.Name.Local)
}

func (p *Parser) unknownAttribute(root xml.StartElement, attr xml.Attr) {
	fmt.Printf("unknown attribute %v for %v\n", attr.Name.Local, root.Name.Local)
}

func (p *Parser) IterateOverTokens(r xml.TokenReader, h func(t xml.Token) (stop bool, err error)) error {
	for {
		t, err := r.Token()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		stop, err := h(t)
		if err != nil {
			return err
		}
		if stop {
			return nil
		}
	}
}

func (p *Parser) IterateOverElements(r xml.TokenReader, parent xml.StartElement, h func(el xml.StartElement) error) error {
	var startElement xml.StartElement
	return p.IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch el := t.(type) {
		case xml.StartElement:
			startElement = el
			err := h(el)
			if err != nil {
				return false, err
			}
			return false, nil
		case xml.EndElement:
			switch el.Name.Local {
			case startElement.Name.Local:
				startElement = xml.StartElement{}
				return false, nil
			case parent.Name.Local:
				return true, nil
			default:
				return false, nil
			}
		case xml.CharData:
			data := string(el)
			if len(strings.Trim(data, " \n\r")) > 0 {
				fmt.Printf("unexpected token %s for %v\n", t, parent.Name.Local)
			}
			return false, nil
		default:
			fmt.Printf("unexpected token %s for %v\n", t, parent.Name.Local)
			return false, nil
		}
	})
}

func (p *Parser) CharData(r xml.TokenReader) (string, error) {
	t, err := r.Token()
	if err != nil {
		return "", nil
	}

	switch t.(type) {
	case xml.CharData:
		return string(t.(xml.CharData)), nil
	default:
		return "", fmt.Errorf("unknown token (while expecting char-data) %v", t)
	}
}

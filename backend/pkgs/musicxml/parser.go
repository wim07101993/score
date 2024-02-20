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
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return score, err
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
			score.Parts, err = p.parsePartList(r, el)
			return err
		case "part":
			return p.parsePart(r, el, score)
		default:
			return p.unknownElement(r, root, el)
		}
	})
	return score, err
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
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return display.String(), err
}

func (p *Parser) unknownElement(r xml.TokenReader, root xml.StartElement, el xml.StartElement) error {
	fmt.Printf("unknown element %v for %v\n", el.Name.Local, root.Name.Local)
	for {
		t, err := r.Token()
		if err != nil {
			return err
		}

		switch e := t.(type) {
		case xml.EndElement:
			if e.Name.Local == root.Name.Local {
				return nil
			}
		}
	}
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
		case xml.Comment:
			// IGNORE comments
			return false, nil
		case xml.ProcInst:
			// IGNORE
			return false, nil
		case xml.Directive:
			// IGNORE
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

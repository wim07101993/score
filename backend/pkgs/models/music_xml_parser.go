package models

import (
	"encoding/xml"
	"fmt"
)

type MusicXmlParser struct {
}

func (p *MusicXmlParser) FromXml(r xml.TokenReader) (*Score, error) {
	root := xml.StartElement{
		Name: xml.Name{Local: "root"},
	}
	var score *Score
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "score-partwise":
			var err error
			score, err = p.parseScorePartwise(r, el)
			return err
		default:
			p.unknownElement(root, el)
			return nil
		}
	})
	if err != nil {
		return nil, err
	}
	return score, nil
}

func (p *MusicXmlParser) parseScorePartwise(r xml.TokenReader, root xml.StartElement) (*Score, error) {
	score := &Score{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "work":
			return p.parseWorkElementsIntoScore(r, el, score)
		case "identification":
			return p.parseIdentificationIntoScore(r, el, score)
		case "part-list":
			var err error
			score.PartList, err = p.parsePartList(r, el)
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

func (p *MusicXmlParser) parseWorkElementsIntoScore(r xml.TokenReader, root xml.StartElement, score *Score) error {
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "work-title":
			t, err := r.Token()
			if err != nil {
				return err
			}
			score.Title, err = p.CharData(t)
			fmt.Println("root: ", el.Name.Local, "\t data: ", score.Title)
			return nil
		default:
			p.unknownElement(root, el)
			return nil
		}
	})
}

func (p *MusicXmlParser) parseIdentificationIntoScore(r xml.TokenReader, root xml.StartElement, score *Score) error {
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

func (p *MusicXmlParser) parseCreatorIntoScore(r xml.TokenReader, root xml.StartElement, score *Score) error {
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
				fmt.Printf("root: %v\t composer:  %v\n", root.Name.Local, attr.Value)
				score.Composers = append(score.Composers, attr.Value)
			case "lyricist":
				fmt.Printf("root: %v\t lyricist:  %v\n", root.Name.Local, attr.Value)
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

func (p *MusicXmlParser) parsePartList(r xml.TokenReader, root xml.StartElement) ([]PartGroup, error) {
	fmt.Println("TODO parse part-list")
	return nil, nil
}

func (p *MusicXmlParser) parsePart(r xml.TokenReader, score *Score) error {
	fmt.Println("TODO parse part")
	return nil
}

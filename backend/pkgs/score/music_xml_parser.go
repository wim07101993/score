package score

import (
	"encoding/xml"
	"fmt"
)

type MusicXmlParser struct {
}

func (p *MusicXmlParser) FromXml(r xml.TokenReader) (*Score, error) {
	score := &Score{}
	err := IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.StartElement:
			switch el.Name.Local {
			case "score-partwise":
				return false, p.parseScorePartwise(r, score)
			default:
				return false, nil
			}
		case xml.EndElement:
			if el.Name.Local == "work-title" {
				return true, nil
			}
			return false, fmt.Errorf("unknown end element for 'score-partwise': %v", el)
		}
		return false, nil
	})
	if err != nil {
		return nil, err
	}
	return score, nil
}

func (p *MusicXmlParser) parseScorePartwise(r xml.TokenReader, score *Score) error {
	return IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.StartElement:
			switch el.Name.Local {
			case "work":
				return false, p.parseWorkElements(r, score)
			case "identification":
				return false, p.parseIdentification(r, score)
			case "part-list":
				return false, p.parsePartList(r, score)
			case "part":
				return false, p.parsePart(r, score)
			default:
				fmt.Printf("unknown element %v\n", el)
				return false, nil
			}
		case xml.EndElement:
			if el.Name.Local == "score-partwise" {
				return true, nil
			}
			return false, fmt.Errorf("unknown end element for 'score-partwise': %v", el)
		}
		return false, nil
	})
}

func (p *MusicXmlParser) parseWorkElements(r xml.TokenReader, score *Score) error {
	return IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.StartElement:
			switch el.Name.Local {
			case "work-title":
				t, err := r.Token()
				if err != nil {
					return false, err
				}
				score.Title, err = CharData(t)
				return false, p.ensureElementClosed(r, "work-title")
			}
			return false, fmt.Errorf("unknown element %v", el)
		case xml.EndElement:
			if el.Name.Local == "work" {
				return true, nil
			}
			return false, fmt.Errorf("unknown end element for 'work': %v", el)
		}
		return false, nil
	})
}

func (p *MusicXmlParser) parseIdentification(r xml.TokenReader, score *Score) error {
	return IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.StartElement:
			switch el.Name.Local {
			case "creator":
				return false, p.parseCreator(r, el, score)
			}
			fmt.Printf("unknown element %v\n", el)
			return false, nil
		case xml.EndElement:
			if el.Name.Local == "identification" {
				return true, nil
			}
			return false, fmt.Errorf("unknown end element for 'identification': %v", el)
		}
		return false, nil
	})
}

func (p *MusicXmlParser) parseCreator(r xml.TokenReader, start xml.StartElement, score *Score) error {
	var val string
	err := IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.CharData:
			val = string(el)
			return false, nil
		case xml.EndElement:
			if el.Name.Local == "creator" {
				return true, nil
			}
			return false, fmt.Errorf("unknown end element for 'creator': %v", el)
		default:
			fmt.Printf("unknown token for 'creator': %v\n", el)
		}
		return false, nil
	})
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
				score.Composers = append(score.Composers, attr.Value)
			case "lyricist":
				score.Lyricists = append(score.Lyricists, attr.Value)
			default:
				fmt.Printf("unknown type of creator %v", attr.Value)
			}
		default:
			fmt.Printf("unknown creator attribute %v", attr)
		}
	}
	return nil
}

func (p *MusicXmlParser) parsePartList(r xml.TokenReader, score *Score) error {
	fmt.Println("TODO parse part list")
	return IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.EndElement:
			if el.Name.Local == "part-list" {
				return true, nil
			}
		}
		return false, nil
	})
}

func (p *MusicXmlParser) parsePart(r xml.TokenReader, score *Score) error {
	fmt.Println("TODO parse part")
	return IterateOverTokens(r, func(t xml.Token) (bool, error) {
		switch el := t.(type) {
		case xml.EndElement:
			if el.Name.Local == "part" {
				return true, nil
			}
		}
		return false, nil
	})
}

func (p *MusicXmlParser) ensureElementClosed(r xml.TokenReader, name string) error {
	t, err := r.Token()
	if err != nil {
		return err
	}
	switch el := t.(type) {
	case xml.EndElement:
		if el.Name.Local == name {
			return nil
		}
		return fmt.Errorf("found closing element %s but expected %s", el.Name.Local, name)
	default:
		return fmt.Errorf("expected closing element but found %s", t)
	}
}

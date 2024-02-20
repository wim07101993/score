package musicxml

import (
	"encoding/xml"
	"score/backend/pkgs/models"
)

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
				parent := open[len(open)-1]
				parent.PartGroups = append(parent.PartGroups, pg)
				open = append(open, pg)
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
			return p.unknownElement(r, root, el)
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
			err = p.unknownElement(r, root, el)
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
			err = p.unknownElement(r, root, el)
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
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return instrument, err
}

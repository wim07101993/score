package musicxml

import (
	"encoding/xml"
	"score/backend/pkgs/models"
)

func (p *Parser) parsePartList(start xml.StartElement) (*models.PartGroup, error) {
	ret := &models.PartGroup{}
	open := []*models.PartGroup{ret}
	err := p.readObject(start, nil, func(el xml.StartElement) error {
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
				pg, err := p.parsePartGroup(el, id)
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
				err := p.readUntilClose(el)
				if err != nil {
					return err
				}
			}
			return nil

		case "score-part":
			part, err := p.parseScorePart(el)
			if err != nil {
				return err
			}
			pg := open[len(open)-1]
			pg.Parts = append(pg.Parts, part)
			return nil

		default:
			p.unknownElement(start, el)
			return p.ignoreObject(el)
		}
	})
	return ret, err
}

func (p *Parser) parsePartGroup(start xml.StartElement, id string) (*models.PartGroup, error) {
	pg := &models.PartGroup{Id: id}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type", "number":
				// IGNORE this is parsed in calling method to determine whether
				// part group is ending or starting
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "group-symbol":
				pg.Symbol, err = p.readString(el)
			default:
				p.unknownElement(start, el)
				return p.ignoreObject(el)
			}
			return err
		})
	return pg, err
}

func (p *Parser) parseScorePart(start xml.StartElement) (*models.Part, error) {
	part := &models.Part{}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				part.Id = attr.Value
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "part-name":
				part.Name, err = p.readString(el)
			case "part-name-display":
				part.NameDisplay, err = p.parseDisplayText(el)
			case "part-abbreviation":
				part.Name, err = p.readString(el)
			case "part-abbreviation-display":
				part.AbbreviationDisplay, err = p.parseDisplayText(el)
			case "score-instrument":
				part.Instrument, err = p.parseInstrument(el)
			default:
				p.unknownElement(start, el)
				err = p.ignoreObject(el)
			}
			return err
		})
	return part, err
}

func (p *Parser) parseInstrument(start xml.StartElement) (string, error) {
	var instrument string
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				//ignore
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "instrument-name":
				instrument, err = p.readString(el)
			default:
				p.unknownElement(start, el)
				err = p.ignoreObject(el)
			}
			return err
		})
	return instrument, err
}

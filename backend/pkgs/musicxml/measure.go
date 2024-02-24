package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
	"strconv"
)

func (p *Parser) parseMeasure(start xml.StartElement) (*models.Measure, error) {
	m := &models.Measure{}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				n, err := strconv.Atoi(attr.Value)
				if err != nil {
					return err
				}
				m.Number = n
			case "width":
				// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "attributes":
				err = p.parsePartAttributesIntoMeasure(el, m)
			case "direction":
				err = p.parseDirectionIntoMeasure(el, m)
			case "note", "backup", "barline", "print", "harmony":
				err = p.ignoreObject(el)
			default:
				p.unknownElement(start, el)
				err = p.ignoreObject(el)
			}
			return err
		})

	return m, err
}

func (p *Parser) parsePartAttributesIntoMeasure(start xml.StartElement, measure *models.Measure) error {
	if measure == nil {
		return fmt.Errorf("unknown part (%v)", start)
	}
	return p.readObject(start, nil, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "key":
			measure.Key, err = p.parseKey(el)
		case "time":
			measure.TimeSignature, err = p.parseTimeSignature(el)
		case "staves":
			staveCount, err := p.readInt(el)
			if err != nil {
				return err
			}
			measure.Staves = make([]models.Stave, staveCount)
			for i := range measure.Staves {
				measure.Staves[i].Number = i + 1
			}
		case "clef":
			staveNr, clef, err := p.parseClef(el)
			if err != nil {
				return err
			}
			for i := range measure.Staves {
				if measure.Staves[i].Number == staveNr {
					measure.Staves[i].Clef = clef
					return nil
				}
			}
			return fmt.Errorf("no stave found with number %v", staveNr)
		case "transpose":
			measure.Transpose, err = p.parseTranspose(el)
		case "divisions", "staff-details":
			err = p.ignoreObject(el)
		default:
			p.unknownElement(start, el)
			err = p.ignoreObject(el)
		}
		return err
	})
}

func (p *Parser) parseKey(start xml.StartElement) (*models.Key, error) {
	var fifths int
	var mode string
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "color":
				// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "fifths":
				fifths, err = p.readInt(el)
			case "mode":
				mode, err = p.readString(el)
			}
			return err
		})

	if err != nil {
		return nil, err
	}

	key := &models.Key{Mode: mode}
	if mode == "minor" {
		key.Tone, err = FifthsToMinorTone(fifths)
		return key, err
	}
	key.Tone, err = FifthsToMajorTone(fifths)
	return key, err
}

func (p *Parser) parseTimeSignature(start xml.StartElement) (*models.TimeSignature, error) {
	t := &models.TimeSignature{}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "color", "symbol":
				// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "beats":
				t.Beats, err = p.readInt(el)
			case "beat-type":
				t.BeatLength, err = p.readInt(el)
			}
			return err
		})
	return t, err
}

func (p *Parser) parseClef(start xml.StartElement) (staveNr int, clef models.Clef, err error) {
	err = p.readObject(start,
		func(attr xml.Attr) error {
			var err error
			switch attr.Name.Local {
			case "number":
				staveNr, err = strconv.Atoi(attr.Value)
			case "color":
				// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return err
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "sign":
				clef.Sign, err = p.readString(el)
			case "line":
				clef.Line, err = p.readInt(el)
			default:
				p.unknownElement(start, el)
				err = p.ignoreObject(el)
			}
			return err
		})
	return staveNr, clef, err
}

func (p *Parser) parseDirectionIntoMeasure(start xml.StartElement, measure *models.Measure) error {
	var metronome *models.Metronome
	return p.readObject(start, nil, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "direction-type":
			return p.readObject(el, nil, func(el2 xml.StartElement) error {
				var err error
				switch el2.Name.Local {
				case "metronome":
					metronome, err = p.parseMetronome(el2)
				default:
					p.unknownElement(el, el2)
					return p.ignoreObject(el2)
				}
				return err
			})
		case "staff":
			staffNr, err := p.readInt(el)
			if err != nil {
				return err
			}
			for i := range measure.Staves {
				if measure.Staves[i].Number == staffNr {
					measure.Staves[i].Metronome = metronome
					return nil
				}
			}
			return fmt.Errorf("staff with nr %v not found for metronome ", staffNr)
		case "voice":
			return p.ignoreObject(el)
		default:
			p.unknownElement(start, el)
			return p.ignoreObject(el)
		}
	})
}

func (p *Parser) parseMetronome(start xml.StartElement) (*models.Metronome, error) {
	m := &models.Metronome{}
	err := p.readObject(start,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "color", "default-y", "font-family", "font-style", "font-size", "font-weight":
				// IGNORE
			default:
				p.unknownAttribute(start, attr)
			}
			return nil
		},
		func(el xml.StartElement) error {
			var err error
			switch el.Name.Local {
			case "beat-unit":
				m.BeatUnit, err = p.readString(el)
			case "per-minute":
				m.PerMinute, err = p.readString(el)
			default:
				p.unknownElement(start, el)
				err = p.ignoreObject(el)
			}
			return err
		})
	return m, err
}

func (p *Parser) parseTranspose(start xml.StartElement) (*models.Transpose, error) {
	t := &models.Transpose{}
	err := p.readObject(start, nil, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "chromatic":
			t.Chromatic, err = p.readFloat(el)
		case "diatonic":
			t.Diatonic, err = p.readInt(el)
		case "octave-change":
			t.OctaveChange, err = p.readInt(el)
		case "double":
			s, err := p.readString(el)
			if err != nil {
				return err
			}
			switch s {
			case "yes":
				t.Double = true
			case "no":
				t.Double = false
			default:
				return fmt.Errorf("unknown yes-no value for 'double': %v", s)
			}
		}
		return err
	})
	return t, err
}

func FifthsToMajorTone(fifths int) (string, error) {
	switch fifths {
	case -7:
		return "C♭", nil
	case -6:
		return "G♭", nil
	case -5:
		return "D♭", nil
	case -4:
		return "A♭", nil
	case -3:
		return "E♭", nil
	case -2:
		return "B♭", nil
	case -1:
		return "F", nil
	case 0:
		return "C", nil
	case 1:
		return "G", nil
	case 2:
		return "D", nil
	case 3:
		return "A", nil
	case 4:
		return "E", nil
	case 5:
		return "B", nil
	case 6:
		return "F♯", nil
	case 7:
		return "C♯", nil
	default:
		return "", fmt.Errorf("there is no major %v fifth", fifths)
	}
}

func FifthsToMinorTone(fifths int) (string, error) {
	switch fifths {
	case -7:
		return "A♭", nil
	case -6:
		return "E♭", nil
	case -5:
		return "B♭", nil
	case -4:
		return "F", nil
	case -3:
		return "C", nil
	case -2:
		return "G", nil
	case -1:
		return "D", nil
	case 0:
		return "A", nil
	case 1:
		return "E", nil
	case 2:
		return "B", nil
	case 3:
		return "F♯", nil
	case 4:
		return "C♯", nil
	case 5:
		return "G♯", nil
	case 6:
		return "D♯", nil
	case 7:
		return "A♯", nil
	default:
		return "", fmt.Errorf("there is no minor %v fifth", fifths)
	}
}

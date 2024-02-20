package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
	"strconv"
)

func (p *Parser) parseMeasure(r xml.TokenReader, root xml.StartElement) (*models.Measure, error) {
	m := &models.Measure{}
	for _, attr := range root.Attr {
		switch attr.Name.Local {
		case "number":
			n, err := strconv.Atoi(attr.Value)
			if err != nil {
				return m, err
			}
			m.Number = n
		case "width":
			// IGNORE
		default:
			p.unknownAttribute(root, attr)
		}
	}

	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "attributes":
			err = p.parsePartAttributesIntoMeasure(r, el, m)
		case "direction":
			err = p.parseDirectionIntoMeasure(r, el, m)
		case "note":
			// TODO parse notes
			err = p.IgnoreElement(r, el)
		case "backup":
			err = p.IgnoreElement(r, el)
		case "barline":
			// TODO parse barlines
			err = p.IgnoreElement(r, el)
		case "print":
			err = p.IgnoreElement(r, el)
		case "harmony":
			// TODO parse harmonies
			err = p.IgnoreElement(r, el)
		default:
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return m, err
}

func (p *Parser) parsePartAttributesIntoMeasure(r xml.TokenReader, root xml.StartElement, measure *models.Measure) error {
	if measure == nil {
		return fmt.Errorf("unknown part (%v)", root)
	}
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "divisions":
			err = p.IgnoreElement(r, el)
		case "key":
			measure.Key, err = p.parseKey(r, el)
		case "time":
			measure.TimeSignature, err = p.parseTimeSignature(r, el)
		case "staves":
			s, err := p.CharData(r)
			if err != nil {
				return err
			}
			staveCount, err := strconv.Atoi(s)
			measure.Staves = make([]models.Stave, staveCount)
			for i := range measure.Staves {
				measure.Staves[i].Number = i + 1
			}
		case "clef":
			var staveNr int
			var clef models.Clef
			staveNr, clef, err = p.parseClef(r, el)
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
		case "staff-details":
			// IGNORE
			return nil
		case "transpose":
			measure.Transpose, err = p.parseTranspose(r, el)
		default:
			return p.unknownElement(r, root, el)
		}
		return err
	})
}

func (p *Parser) parseKey(r xml.TokenReader, root xml.StartElement) (*models.Key, error) {
	var fifths int
	var mode string
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "fifths":
			var v string
			v, err = p.CharData(r)
			if err != nil {
				return err
			}
			fifths, err = strconv.Atoi(v)
		case "mode":
			mode, err = p.CharData(r)
		}
		return err
	})

	key := &models.Key{Mode: mode}
	if mode == "minor" {
		key.Tone, err = FifthsToMinorTone(fifths)
		return key, err
	}
	key.Tone, err = FifthsToMajorTone(fifths)
	return key, err
}

func (p *Parser) parseTimeSignature(r xml.TokenReader, root xml.StartElement) (*models.TimeSignature, error) {
	t := &models.TimeSignature{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "beats":
			var v string
			v, err = p.CharData(r)
			if err != nil {
				return err
			}
			t.Beats, err = strconv.Atoi(v)
		case "beat-type":
			var v string
			v, err = p.CharData(r)
			if err != nil {
				return err
			}
			t.BeatLength, err = strconv.Atoi(v)
		}
		return err
	})
	return t, err
}

func (p *Parser) parseClef(r xml.TokenReader, root xml.StartElement) (staveNr int, clef models.Clef, err error) {
	for _, attr := range root.Attr {
		switch attr.Name.Local {
		case "number":
			staveNr, err = strconv.Atoi(attr.Value)
		}
	}
	if err != nil {
		return
	}

	err = p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "sign":
			clef.Sign, err = p.CharData(r)
		case "line":
			l, err := p.CharData(r)
			if err != nil {
				return err
			}
			clef.Line, err = strconv.Atoi(l)
		default:
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return staveNr, clef, err
}

func (p *Parser) parseDirectionIntoMeasure(r xml.TokenReader, root xml.StartElement, measure *models.Measure) error {
	var metronome *models.Metronome
	return p.IterateOverElements(r, root, func(el xml.StartElement) error {
		switch el.Name.Local {
		case "direction-type":
			return p.IterateOverElements(r, el, func(el2 xml.StartElement) error {
				var err error
				switch el2.Name.Local {
				case "metronome":
					metronome, err = p.parseMetronome(r, el2)
				default:
					return p.unknownElement(r, el, el2)
				}
				return err
			})

		case "voice":
			return p.IgnoreElement(r, el)
		case "staff":
			s, err := p.CharData(r)
			if err != nil {
				return err
			}
			staffNr, err := strconv.Atoi(s)
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
		default:
			return p.unknownElement(r, root, el)
		}
	})
}

func (p *Parser) parseMetronome(r xml.TokenReader, root xml.StartElement) (*models.Metronome, error) {
	m := &models.Metronome{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "beat-unit":
			m.BeatUnit, err = p.CharData(r)
		case "per-minute":
			m.PerMinute, err = p.CharData(r)
		default:
			err = p.unknownElement(r, root, el)
		}
		return err
	})
	return m, err
}

func (p *Parser) parseTranspose(r xml.TokenReader, root xml.StartElement) (*models.Transpose, error) {
	t := &models.Transpose{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		var s string
		switch el.Name.Local {
		case "chromatic":
			s, err = p.CharData(r)
			if err != nil {
				return err
			}
			t.Chromatic, err = strconv.ParseFloat(s, 64)
		case "diatonic":
			s, err = p.CharData(r)
			if err != nil {
				return err
			}
			t.Diatonic, err = strconv.Atoi(s)
		case "octave-change":
			s, err = p.CharData(r)
			if err != nil {
				return err
			}
			t.OctaveChange, err = strconv.Atoi(s)
		case "double":
			s, err = p.CharData(r)
			if err != nil {
				return err
			}
			switch s {
			case "yes":
				t.Double = true
			case "no":
				t.Double = false
			default:
				err = fmt.Errorf("unknown yes-no value for 'double': %v", s)
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

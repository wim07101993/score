package musicxml

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/models"
	"strconv"
)

func (p *Parser) parseMeasure(r xml.TokenReader, root xml.StartElement) (*models.Measure, error) {
	m := &models.Measure{}
	err := p.IterateOverElements(r, root, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "attributes":
			err = p.parsePartAttributesIntoMeasure(r, el, m)
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
			// IGNORE divisions
			return nil
		case "key":
			measure.Key, err = p.parseKey(r, el)
		case "time":
			fmt.Println("HERE")
			measure.TimeSignature, err = p.parseTimeSignature(r, el)
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

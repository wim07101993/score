package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Metronome struct {
	BeatUnit    string
	PerMinute   int
	BeatUnitDot bool
}

func readMetronome(r xml.TokenReader, element xml.StartElement) (metronome *Metronome, err error) {
	metronome = &Metronome{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "beat-unit":
				if metronome.BeatUnit != "" {
					return &FieldAlreadySet{element, el}
				}
				metronome.BeatUnit, err = ReadString(r, el)
			case "beat-unit-dot":
				if metronome.BeatUnitDot {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				metronome.BeatUnitDot = true
			case "per-minute":
				if metronome.PerMinute != 0 {
					return &FieldAlreadySet{element, el}
				}
				metronome.PerMinute, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return metronome, err
}

func writeMetronome(w *xml.Encoder, name string, metronome *Metronome) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "beat-unit", metronome.BeatUnit, nil)
		},
		func() error {
			if metronome.BeatUnitDot {
				return WriteObject(w, "beat-unit-dot", nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "per-minute", strconv.Itoa(metronome.PerMinute), nil)
		})
}

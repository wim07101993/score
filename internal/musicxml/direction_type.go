package musicxml

import "encoding/xml"

type DirectionType struct {
	Metronome      *Metronome
	Words          []string
	Dynamics       []*Dynamic
	Wedge          *Wedge
	OtherDirection string
	OctaveShift    *OctaveShift
	Segno          bool
	Pedal          *Pedal
}

func readDirectionType(r xml.TokenReader, element xml.StartElement) (tp DirectionType, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "words":
				words, err := ReadString(r, el)
				if err != nil {
					return err
				}
				tp.Words = append(tp.Words, words)
			case "metronome":
				if tp.Metronome != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.Metronome, err = readMetronome(r, el)
			case "dynamics":
				dynamic, err := readDynamic(r, el)
				if err != nil {
					return err
				}
				tp.Dynamics = append(tp.Dynamics, dynamic)
			case "wedge":
				if tp.Wedge != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.Wedge, err = readWedge(r, el)
			case "other-direction":
				if tp.OtherDirection != "" {
					return &FieldAlreadySet{element, el}
				}
				tp.OtherDirection, err = ReadString(r, el)
			case "octave-shift":
				if tp.OctaveShift != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.OctaveShift, err = readOctaveShift(r, el)
			case "segno":
				if tp.Segno {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				tp.Segno = true
			case "pedal":
				if tp.Pedal != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.Pedal, err = pedal(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return tp, err
}

func writeDirectionType(w *xml.Encoder, name string, direction DirectionType) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if direction.Segno {
				return WriteObject(w, "segno", nil)
			}
			return nil
		},
		func() error {
			for _, words := range direction.Words {
				return WriteString(w, "words", words, nil)
			}
			return nil
		},
		func() error {
			if direction.Wedge != nil {
				return writeWedge(w, "wedge", direction.Wedge)
			}
			return nil
		},
		func() error {
			for _, dynamic := range direction.Dynamics {
				if err = writeDynamic(w, "dynamics", dynamic); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if direction.Metronome != nil {
				return writeMetronome(w, "metronome", direction.Metronome)
			}
			return nil
		},
		func() error {
			if direction.OctaveShift != nil {
				return writeOctaveShift(w, "octave-shift", direction.OctaveShift)
			}
			return nil
		},
		func() error {
			if direction.OtherDirection != "" {
				return WriteString(w, "other-direction", direction.OtherDirection, nil)
			}
			return nil
		},
	)
}

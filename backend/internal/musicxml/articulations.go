package musicxml

import "encoding/xml"

type Articulations struct {
	Tenuto     bool
	Staccato   bool
	BreathMark bool
	Accent     bool
}

func readArticulations(r xml.TokenReader, element xml.StartElement) (art *Articulations, err error) {
	art = &Articulations{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tenuto":
				if art.Tenuto {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Tenuto = true
			case "staccato":
				if art.Staccato {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Staccato = true
			case "breath-mark":
				if art.BreathMark {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.BreathMark = true
			case "accent":
				if art.Accent {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Accent = true
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return art, err
}

func writeArticulation(w *xml.Encoder, name string, articulation *Articulations) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if articulation.Staccato {
				if err = WriteObject(w, "staccato", nil); err != nil {
					return err
				}
			}
			if articulation.BreathMark {
				if err = WriteObject(w, "breath-mark", nil); err != nil {
					return nil
				}
			}
			if articulation.Accent {
				if err = WriteObject(w, "accent", nil); err != nil {
					return nil
				}
			}
			if articulation.Tenuto {
				if err = WriteObject(w, "tenuto", nil); err != nil {
					return nil
				}
			}
			return nil
		})
}

package musicxml

import "encoding/xml"

type Bass struct {
	Step  string
	Alter string
}

func readBass(r xml.TokenReader, element xml.StartElement) (bass *Bass, err error) {
	bass = &Bass{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "bass-step":
				if bass.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				bass.Step, err = ReadString(r, el)
			case "bass-alter":
				if bass.Alter != "" {
					return &FieldAlreadySet{element, el}
				}
				bass.Alter, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return bass, err
}

func writeBass(w *xml.Encoder, name string, bass *Bass) (err error) {
	def := Bass{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "bass-step", bass.Step, nil)
		},
		func() error {
			if bass.Alter != def.Alter {
				return WriteString(w, "bass-alter", bass.Alter, nil)
			}
			return nil
		})
}

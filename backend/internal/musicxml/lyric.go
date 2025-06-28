package musicxml

import "encoding/xml"

type Lyric struct {
	Number   string
	Syllabic string
	Text     string
	Extend   *Extend
}

func readLyric(r xml.TokenReader, element xml.StartElement) (lyric *Lyric, err error) {
	lyric = &Lyric{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				lyric.Number = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "syllabic":
				if lyric.Syllabic != "" {
					return &FieldAlreadySet{element, el}
				}
				lyric.Syllabic, err = ReadString(r, el)
			case "text":
				if lyric.Text != "" {
					return &FieldAlreadySet{element, el}
				}
				lyric.Text, err = ReadString(r, el)
			case "extend":
				if lyric.Extend != nil {
					return &FieldAlreadySet{element, el}
				}
				lyric.Extend, err = readExtend(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return lyric, err
}

func writeLyric(w *xml.Encoder, name string, lyric *Lyric) (err error) {
	def := Lyric{}
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "number"}, Value: lyric.Number}},
		func() error {
			if lyric.Syllabic != def.Syllabic {
				return WriteString(w, "syllabic", lyric.Syllabic, nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "text", lyric.Text, nil)
		},
		func() error {
			if lyric.Extend != nil {
				return writeExtend(w, "extend", lyric.Extend)
			}
			return nil
		})
}

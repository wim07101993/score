package musicxml

import "encoding/xml"

type Defaults struct {
	LyricLanguage string
}

func readDefaults(r xml.TokenReader, element xml.StartElement) (defaults *Defaults, err error) {
	defaults = &Defaults{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "scaling", "page-layout", "system-layout", "staff-layout",
				"appearance", "music-font", "word-font", "lyric-font":
				return ReadUntilClose(r, el)
			case "lyric-language":
				defaults.LyricLanguage, err = readLanguage(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return defaults, err
}

func writeDefaults(w *xml.Encoder, name string, defaults *Defaults) (err error) {
	def := Defaults{}
	return WriteObject(w, name, nil,
		func() error {
			if defaults.LyricLanguage != def.LyricLanguage {
				return writeLanguage(w, "lyric-language", defaults.LyricLanguage)
			}
			return nil
		})
}

func readLanguage(r xml.TokenReader, element xml.StartElement) (lang string, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "lang":
				lang = attr.Value
			default:
				err = &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return lang, err
}

func writeLanguage(w *xml.Encoder, name string, language string) error {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "xml:lang"}, Value: language}},
	)
}

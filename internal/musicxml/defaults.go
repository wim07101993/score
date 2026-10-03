package musicxml

import "encoding/xml"

type Defaults struct {
	LyricLanguage string
}

func readDefaults(r xml.TokenReader, element xml.StartElement) (defaults *Defaults, err error) {
	defaults = &Defaults{}
	err = ReadObject(r, element,
		// None of its attributes are needed; see ReadObject.
		nil,
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "scaling", "page-layout", "system-layout", "staff-layout",
				"appearance", "music-font", "word-font", "lyric-font":
				return ReadUntilClose(r, el)
			case "lyric-language":
				defaults.LyricLanguage, err = readLanguage(r, el)
			default:
				// Not needed here; see ReadObject.
				err = ReadUntilClose(r, el)
			}
			return err
		})
	return defaults, err
}

func readLanguage(r xml.TokenReader, element xml.StartElement) (lang string, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "lang":
				lang = attr.Value
			default:
				// Not needed here; see ReadObject.
			}
			return err
		},
		// It holds nothing but its attributes; see ReadObject for why anything
		// that turns up in it anyway is skipped.
		nil)
	return lang, err
}

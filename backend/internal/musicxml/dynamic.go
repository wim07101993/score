package musicxml

import "encoding/xml"

type Dynamic struct {
	Values []string
}

func readDynamic(r xml.TokenReader, element xml.StartElement) (dynamic *Dynamic, err error) {
	dynamic = &Dynamic{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "p", "pp", "ppp", "pppp", "ppppp", "pppppp",
				"f", "ff", "fff", "ffff", "fffff", "ffffff",
				"mp", "mf", "sf", "sfp", "sfpp",
				"fp", "rf", "rfz", "sfz", "sffz", "fz",
				"n", "pf", "sfzp":
				err = ReadUntilClose(r, el)
				dynamic.Values = append(dynamic.Values, el.Name.Local)
			case "other-dynamics":
				val, err := ReadString(r, el)
				if err != nil {
					return err
				}
				dynamic.Values = append(dynamic.Values, val)
			}
			return err
		})
	return dynamic, err
}

func writeDynamic(w *xml.Encoder, name string, dynamic *Dynamic) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, dynamic := range dynamic.Values {
				if err = WriteObject(w, dynamic, nil); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

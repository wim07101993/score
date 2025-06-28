package musicxml

import (
	"encoding/xml"
	"strconv"
)

type TimeSignature struct {
	Symbol   string
	Beats    int
	BeatType string
}

func readTimeSignature(r xml.TokenReader, element xml.StartElement) (time *TimeSignature, err error) {
	time = &TimeSignature{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "symbol":
				time.Symbol = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "beats":
				if time.Beats != 0 {
					return &FieldAlreadySet{element, el}
				}
				time.Beats, err = ReadInt(r, el)
			case "beat-type":
				if time.BeatType != "" {
					return &FieldAlreadySet{element, el}
				}
				time.BeatType, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return time, err
}

func writeTimeSignature(w *xml.Encoder, name string, time *TimeSignature) (err error) {
	def := TimeSignature{}
	var attrs []xml.Attr
	if time.Symbol != def.Symbol {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "symbol"}, Value: time.Symbol})
	}
	return WriteObject(w, name, attrs,
		func() error {
			return WriteString(w, "beats", strconv.Itoa(time.Beats), nil)
		},
		func() error {
			return WriteString(w, "beat-type", time.BeatType, nil)
		},
	)
}

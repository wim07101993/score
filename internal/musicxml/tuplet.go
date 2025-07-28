package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Tuplet struct {
	Type       string
	Number     int
	Bracket    bool
	ShowNumber string
	ShowType   string
	Values     []TupletValue
}

func readTuplet(r xml.TokenReader, element xml.StartElement) (tuplet *Tuplet, err error) {
	tuplet = &Tuplet{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				tuplet.Type = attr.Value
			case "number":
				n, err := strconv.Atoi(attr.Value)
				if err != nil {
					return err
				}
				tuplet.Number = n
			case "bracket":
				tuplet.Bracket = attr.Value == "yes"
			case "show-number":
				tuplet.ShowNumber = attr.Value
			case "show-type":
				tuplet.ShowType = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuplet-actual":
				val, err := readTupletPortion(r, el)
				if err != nil {
					return err
				}
				tuplet.Values = append(tuplet.Values, TupletValue{Actual: val})
			case "tuplet-normal":
				val, err := readTupletPortion(r, el)
				if err != nil {
					return err
				}
				tuplet.Values = append(tuplet.Values, TupletValue{Normal: val})
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tuplet, err
}

func writeTuplet(w *xml.Encoder, name string, tuplet *Tuplet) (err error) {
	def := Tuplet{}

	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: tuplet.Type},
	}

	if tuplet.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(tuplet.Number)})
	}
	if tuplet.Bracket != def.Bracket {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "bracket"}, Value: "yes"})
	}
	if tuplet.ShowNumber != def.ShowNumber {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "show-number"}, Value: tuplet.ShowNumber})
	}
	if tuplet.ShowType != def.ShowType {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "show-type"}, Value: tuplet.ShowType})
	}

	return WriteObject(w, name, attrs,
		func() error {
			for _, value := range tuplet.Values {
				if value.Actual != nil {
					if err = writeTupletPortion(w, "tuplet-actual", value.Actual); err != nil {
						return err
					}
				}
				if value.Normal != nil {
					if err = writeTupletPortion(w, "tuplet-normal", value.Actual); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Glissando struct {
	Type     string
	Number   int
	LineType string
}

func readGlissando(r xml.TokenReader, element xml.StartElement) (glissando *Glissando, err error) {
	glissando = &Glissando{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				glissando.Type = attr.Value
			case "number":
				num, err := strconv.Atoi(attr.Value)
				if err != nil {
					return err
				}
				glissando.Number = num
			case "line-type":
				glissando.LineType = attr.Value
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return glissando, err
}

func writeGlissando(w *xml.Encoder, name string, glissando *Glissando) (err error) {
	def := Glissando{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: glissando.Type},
	}
	if glissando.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(glissando.Number)})
	}
	if glissando.LineType != def.LineType {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "lineType"}, Value: glissando.LineType})
	}
	return WriteObject(w, name, attrs)
}

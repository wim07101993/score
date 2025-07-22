package musicxml

import (
	"encoding/xml"
	"strconv"
)

type OctaveShift struct {
	Type   string
	Number int
	Size   int
}

func readOctaveShift(r xml.TokenReader, element xml.StartElement) (shift *OctaveShift, err error) {
	shift = &OctaveShift{Size: 8}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				shift.Type = attr.Value
			case "number":
				shift.Number, err = strconv.Atoi(attr.Value)
			case "size":
				shift.Size, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return shift, err
}

func writeOctaveShift(w *xml.Encoder, name string, octaveShift *OctaveShift) (err error) {
	def := OctaveShift{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: octaveShift.Type},
	}
	if octaveShift.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(octaveShift.Number)})
	}
	if octaveShift.Size != def.Size {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "size"}, Value: octaveShift.Type})
	}
	return WriteObject(w, name, attrs)
}

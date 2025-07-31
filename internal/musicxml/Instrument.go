package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Instrument struct {
	Id       string
	Name     string
	Sound    string
	IsSolo   bool
	Ensemble *int
}

func readInstrument(r xml.TokenReader, element xml.StartElement) (instr *Instrument, err error) {
	instr = &Instrument{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				instr.Id = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "instrument-name":
				instr.Name, err = ReadString(r, el)
			case "instrument-sound":
				instr.Sound, err = ReadString(r, el)
			case "solo":
				instr.IsSolo = true
				err = ReadUntilClose(r, el)
			case "ensemble":
				val, err := ReadString(r, el)
				if err != nil {
					return err
				}
				if val == "" {
					return nil
				}
				ens, err := strconv.Atoi(val)
				if err != nil {
					return err
				}
				instr.Ensemble = &ens
				return nil
			case "virtual-instrument":
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return instr, err
}

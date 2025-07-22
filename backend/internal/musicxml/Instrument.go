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

func writeInstrument(w *xml.Encoder, name string, instr *Instrument) (err error) {
	def := Instrument{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "id"}, Value: instr.Id},
		},
		func() error {
			return WriteString(w, "instrument-name", instr.Name, nil)
		},
		func() error {
			if instr.Sound != def.Sound {
				return WriteString(w, "instrument-sound", instr.Sound, nil)
			}
			return nil
		},
		func() error {
			if instr.IsSolo {
				return WriteObject(w, "solo", nil)
			}
			return nil
		},
		func() error {
			if instr.Ensemble != nil {
				return WriteString(w, "ensemble", strconv.Itoa(*instr.Ensemble), nil)
			}
			return nil
		},
	)
}

func readInstrumentReference(r xml.TokenReader, element xml.StartElement) (id string, err error) {
	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "id":
			id = attr.Value
		default:
			return "", &UnknownAttribute{element, attr}
		}
	}
	return id, ReadUntilClose(r, element)
}

func writeInstrumentReference(w *xml.Encoder, name string, ref string) error {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "id"}, Value: ref},
	})
}

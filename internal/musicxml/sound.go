package musicxml

import (
	"encoding/xml"
	"fmt"
	"strconv"
)

type Sound struct {
	ToCoda         string
	Offset         *Offset
	TimeOnly       string
	Tempo          float32
	Dynamics       float32
	DaCapo         bool
	Coda           string
	Divisions      float32
	ForwardRepeat  bool
	Fine           string
	Pizzicato      bool
	Pan            float32
	Elevation      float32
	DamperPedal    string
	SoftPedal      string
	SostenutoPedal string
	Segno          bool
	DalSegno       bool
}

func readSound(r xml.TokenReader, element xml.StartElement) (sound *Sound, err error) {
	sound = &Sound{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "tocoda":
				sound.ToCoda = attr.Value
			case "time-only":
				sound.TimeOnly = attr.Value
			case "tempo":
				tempo, err := strconv.ParseFloat(attr.Value, 32)
				sound.Tempo = float32(tempo)
				return err
			case "dynamics":
				dynamics, err := strconv.ParseFloat(attr.Value, 32)
				sound.Dynamics = float32(dynamics)
				return err
			case "dacapo":
				sound.DaCapo = attr.Value == "yes"
			case "segno":
				sound.Segno = attr.Value == "yes"
			case "dalsegno":
				sound.DalSegno = attr.Value == "yes"
			case "coda":
				sound.Coda = attr.Value
			case "divisions":
				divisions, err := strconv.ParseFloat(attr.Value, 32)
				sound.Divisions = float32(divisions)
				return err
			case "forward-repeat":
				sound.ForwardRepeat = attr.Value == "yes"
			case "fine":
				sound.Fine = attr.Value
			case "pizzicato":
				sound.Pizzicato = attr.Value == "yes"
			case "pan":
				pan, err := strconv.ParseFloat(attr.Value, 32)
				sound.Pan = float32(pan)
				return err
			case "elevation":
				elevation, err := strconv.ParseFloat(attr.Value, 32)
				sound.Elevation = float32(elevation)
				return err
			case "damper-pedal":
				sound.DamperPedal = attr.Value
			case "soft-pedal":
				sound.DamperPedal = attr.Value
			case "sostenuto-pedal":
				sound.SostenutoPedal = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "offset":
				if sound.Offset != nil {
					return &FieldAlreadySet{element, el}
				}
				sound.Offset, err = readOffset(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return sound, err
}

func writeSound(w *xml.Encoder, name string, sound *Sound) (err error) {
	def := Sound{}
	var attrs []xml.Attr
	if sound.ToCoda != def.ToCoda {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "tocoda"}, Value: sound.ToCoda})
	}
	if sound.TimeOnly != def.TimeOnly {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "time-only"}, Value: sound.TimeOnly})
	}
	if sound.Tempo != def.Tempo {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "tempo"}, Value: fmt.Sprintf("%g", sound.Tempo)})
	}
	if sound.Dynamics != def.Dynamics {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dynamics"}, Value: fmt.Sprintf("%g", sound.Dynamics)})
	}
	if sound.DaCapo {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dacapo"}, Value: "yes"})
	}
	if sound.Segno {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "segno"}, Value: "yes"})
	}
	if sound.DalSegno {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dalsegno"}, Value: "yes"})
	}
	if sound.Coda != def.Coda {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "coda"}, Value: sound.Coda})
	}
	if sound.Divisions != def.Divisions {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "divisions"}, Value: fmt.Sprintf("%g", sound.Divisions)})
	}
	if sound.ForwardRepeat {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "forward-repeat"}, Value: "yes"})
	}
	if sound.Fine != def.Fine {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "fine"}, Value: sound.Fine})
	}
	if sound.Pizzicato {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "pizzicato"}, Value: "yes"})
	}
	if sound.Pan != def.Pan {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "pan"}, Value: fmt.Sprintf("%g", sound.Pan)})
	}
	if sound.Elevation != def.Elevation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "elevation"}, Value: fmt.Sprintf("%g", sound.Elevation)})
	}
	if sound.DamperPedal != def.DamperPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "damper-pedal"}, Value: sound.DamperPedal})
	}
	if sound.SoftPedal != def.SoftPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "soft-pedal"}, Value: sound.SoftPedal})
	}
	if sound.SostenutoPedal != def.SostenutoPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "sostenuto-pedal"}, Value: sound.SostenutoPedal})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if sound.Offset != nil {
				return writeOffset(w, "offset", sound.Offset)
			}
			return nil
		})
}

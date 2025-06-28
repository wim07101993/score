package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Harmony struct {
	Root    *HarmonyRoot
	Kind    string
	Staff   int
	Bass    *Bass
	Degrees []*Degree
	Frame   *Frame
}

func readHarmony(r xml.TokenReader, element xml.StartElement) (harmony *Harmony, err error) {
	def := Harmony{}
	harmony = &Harmony{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "root":
				if harmony.Root != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Root, err = readHarmonyRoot(r, el)
			case "kind":
				if harmony.Kind != def.Kind {
					return &FieldAlreadySet{element, el}
				}
				harmony.Kind, err = ReadString(r, el)
			case "staff":
				if harmony.Staff != def.Staff {
					return &FieldAlreadySet{element, el}
				}
				harmony.Staff, err = ReadInt(r, el)
			case "bass":
				if harmony.Bass != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Bass, err = readBass(r, el)
			case "degree":
				degree, err := readDegree(r, el)
				if err != nil {
					return err
				}
				harmony.Degrees = append(harmony.Degrees, degree)
			case "frame":
				if harmony.Frame != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Frame, err = readFrame(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return harmony, err
}

func writeHarmony(w *xml.Encoder, name string, harmony *Harmony) (err error) {
	def := Harmony{}
	return WriteObject(w, name, nil,
		func() error {
			if harmony.Root != nil {
				return writeHarmonyRoot(w, "root", harmony.Root)
			}
			return nil
		},
		func() error {
			if harmony.Kind != def.Kind {
				return WriteString(w, "kind", harmony.Kind, nil)
			}
			return nil
		},
		func() error {
			if harmony.Bass != nil {
				return writeBass(w, "bass", harmony.Bass)
			}
			return nil
		},
		func() error {
			for _, degree := range harmony.Degrees {
				if err = writeDegree(w, "degree", degree); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if harmony.Frame != nil {
				return writeFrame(w, "frame", harmony.Frame)
			}
			return nil
		},
		func() error {
			if harmony.Staff != def.Staff {
				return WriteString(w, "staff", strconv.Itoa(harmony.Staff), nil)
			}
			return nil
		})
}

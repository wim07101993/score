package musicxml

import (
	"encoding/xml"
	"fmt"
)

type HarmonyRoot struct {
	Step  Step
	Alter float32
}

func readHarmonyRoot(r xml.TokenReader, element xml.StartElement) (root *HarmonyRoot, err error) {
	root = &HarmonyRoot{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "root-step":
				if root.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				s, err := ReadString(r, el)
				if err != nil {
					return err
				}
				root.Step = Step(s)
			case "root-alter":
				if root.Alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				root.Alter, err = ReadFloat32(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return root, err
}

func writeHarmonyRoot(w *xml.Encoder, name string, root *HarmonyRoot) (err error) {
	def := HarmonyRoot{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "root-step", string(root.Step), nil)
		},
		func() error {
			if root.Alter != def.Alter {
				return WriteString(w, "root-alter", fmt.Sprintf("%g", root.Alter), nil)
			}
			return nil
		})
}

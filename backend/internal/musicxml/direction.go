package musicxml

import (
	"encoding/xml"
	"strconv"
)

type Direction struct {
	DirectionTypes []DirectionType
	Voice          string
	Staff          int
	Offset         *Offset
	Sound          *Sound
	IsDirective    bool
}

func readDirection(r xml.TokenReader, element xml.StartElement) (direction *Direction, err error) {
	direction = &Direction{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "directive":
				direction.IsDirective = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "direction-type":
				tp, err := readDirectionType(r, el)
				if err != nil {
					return err
				}
				direction.DirectionTypes = append(direction.DirectionTypes, tp)
			case "voice":
				if direction.Voice != "" {
					return &FieldAlreadySet{element, el}
				}
				direction.Voice, err = ReadString(r, el)
			case "staff":
				if direction.Staff != 0 {
					return &FieldAlreadySet{element, el}
				}
				direction.Staff, err = ReadInt(r, el)
			case "offset":
				if direction.Offset != nil {
					return &FieldAlreadySet{element, el}
				}
				direction.Offset, err = readOffset(r, el)
			case "sound":
				if direction.Sound != nil {
					return &FieldAlreadySet{element, el}
				}
				direction.Sound, err = readSound(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return direction, err
}

func writeDirection(w *xml.Encoder, name string, direction *Direction) (err error) {
	def := Direction{}
	return WriteObject(w, name, nil,
		func() error {
			for _, direction := range direction.DirectionTypes {
				if err = writeDirectionType(w, "direction-type", direction); err != nil {
					return err
				}
			}
			return err
		},
		func() error {
			if direction.Offset != nil {
				return writeOffset(w, "offset", direction.Offset)
			}
			return nil
		},
		func() error {
			if direction.Voice != def.Voice {
				return WriteString(w, "voice", direction.Voice, nil)
			}
			return nil
		},
		func() error {
			if direction.Staff != def.Staff {
				return WriteString(w, "staff", strconv.Itoa(direction.Staff), nil)
			}
			return nil
		},
		func() error {
			if direction.Sound != nil {
				return writeSound(w, "sound", direction.Sound)
			}
			return nil
		},
	)
}

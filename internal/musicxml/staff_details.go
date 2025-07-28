package musicxml

import (
	"encoding/xml"
	"strconv"
)

type StaffDetails struct {
	Number int
	Lines  *int
	Tuning []*StaffTuning
}

func readStaffDetails(r xml.TokenReader, element xml.StartElement) (staff *StaffDetails, err error) {
	staff = &StaffDetails{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "number":
				staff.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "staff-lines":
				if staff.Lines != nil {
					return &FieldAlreadySet{element, el}
				}
				lines, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				staff.Lines = &lines
			case "staff-tuning":
				tuning, err := readTuning(r, el)
				if err != nil {
					return err
				}
				staff.Tuning = append(staff.Tuning, tuning)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})

	return staff, err
}

func writeStaffDetails(w *xml.Encoder, name string, details *StaffDetails) (err error) {
	def := StaffDetails{}
	var attrs []xml.Attr
	if details.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(details.Number)})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if details.Lines != nil {
				return WriteString(w, "staff-lines", strconv.Itoa(*details.Lines), nil)
			}
			return nil
		},
		func() error {
			for _, tuning := range details.Tuning {
				if err = writeTuning(w, "staff-tuning", tuning); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

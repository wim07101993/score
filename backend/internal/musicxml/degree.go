package musicxml

import "encoding/xml"

type Degree struct {
	Value *DegreeValue
	Alter *DegreeAlter
	Type  *DegreeType
}

func readDegree(r xml.TokenReader, element xml.StartElement) (degree *Degree, err error) {
	degree = &Degree{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "degree-alter":
				if degree.Alter != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Alter, err = readDegreeAlter(r, el)
			case "degree-type":
				if degree.Type != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Type, err = readDegreeType(r, el)
			case "degree-value":
				if degree.Value != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Value, err = readDegreeValue(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return degree, err
}

func writeDegree(w *xml.Encoder, name string, degree *Degree) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return writeDegreeValue(w, "degree-value", degree.Value)
		},
		func() error {
			return writeDegreeAlter(w, "degree-alter", degree.Alter)
		},
		func() error {
			return writeDegreeType(w, "degree-type", degree.Type)
		})
}

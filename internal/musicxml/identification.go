package musicxml

import "encoding/xml"

type Identification struct {
	Creators []*TypedText
	Encoding *Encoding
	Rights   []*TypedText
	Relation []*TypedText
}

func readIdentification(r xml.TokenReader, element xml.StartElement) (id *Identification, err error) {
	id = &Identification{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "creator":
				creator, err := readTypedText(r, el)
				if err != nil {
					return err
				}
				id.Creators = append(id.Creators, creator)
			case "rights":
				rights, err := readTypedText(r, el)
				if err != nil {
					return err
				}
				id.Rights = append(id.Rights, rights)
			case "encoding":
				if id.Encoding != nil {
					return &FieldAlreadySet{element, el}
				}
				id.Encoding, err = readEncoding(r, el)
			case "relation":
				relation, err := readTypedText(r, el)
				if err != nil {
					return err
				}
				id.Relation = append(id.Relation, relation)
			case "miscellaneous":
				err = ReadUntilClose(r, el) // IGNORE
			case "source":
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	if id.Encoding == nil && len(id.Creators) == 0 && len(id.Rights) == 0 && len(id.Relation) == 0 {
		return nil, err
	}
	return id, err
}

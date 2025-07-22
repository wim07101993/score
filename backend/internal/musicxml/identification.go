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

func writeIdentification(w *xml.Encoder, name string, identification *Identification) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, creator := range identification.Creators {
				if err = writeTypedText(w, "creator", creator); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, rights := range identification.Rights {
				if err = writeTypedText(w, "rights", rights); err != nil {
					return nil
				}
			}
			return nil
		},
		func() error {
			if identification.Encoding != nil {
				return writeEncoding(w, "encoding")
			}
			return nil
		},
		func() error {
			for _, relation := range identification.Relation {
				if err = writeTypedText(w, "relation", relation); err != nil {
					return nil
				}
			}
			return nil
		})
}

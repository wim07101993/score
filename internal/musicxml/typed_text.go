package musicxml

import "encoding/xml"

type TypedText struct {
	Type  string
	Value string
}

func readTypedText(r xml.TokenReader, element xml.StartElement) (text *TypedText, err error) {
	text = &TypedText{}

	token, err := r.Token()
	if err != nil {
		return text, err
	}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "type":
			text.Type = attr.Value
		default:
			return text, &UnknownAttribute{element, attr}
		}
	}

	switch el := token.(type) {
	case xml.CharData:
		text.Value = string(el)
	default:
		return text, &UnexpectedTokenError{element, token}
	}

	err = ReadUntilClose(r, element)
	return text, err
}

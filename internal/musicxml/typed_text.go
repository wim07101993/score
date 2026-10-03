package musicxml

import "encoding/xml"

type TypedText struct {
	Type  string
	Value string
}

// readTypedText reads an element that is text with a type next to it, such as
// a creator and what they did.
//
// The text may be empty — an exporter that knows there is a composer but not
// who writes <creator type="composer"/> — and may be broken up by a comment or
// a CDATA section; ReadString takes care of both. Attributes other than the
// type are skipped, as everywhere else; see ReadObject.
func readTypedText(r xml.TokenReader, element xml.StartElement) (text *TypedText, err error) {
	text = &TypedText{}

	for _, attr := range element.Attr {
		if attr.Name.Local == "type" {
			text.Type = attr.Value
		}
	}

	text.Value, err = ReadString(r, element)
	return text, err
}

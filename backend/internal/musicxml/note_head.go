package musicxml

import "encoding/xml"

type NoteHead struct {
	Value       string
	Filled      bool
	Parentheses bool
}

func readNoteHead(r xml.TokenReader, element xml.StartElement) (head *NoteHead, err error) {
	head = &NoteHead{}
	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "filled":
			head.Filled = attr.Value == "yes"
		case "parentheses":
			head.Parentheses = attr.Value == "yes"
		default:
			return head, &UnknownAttribute{element, attr}
		}
	}

	head.Value, err = ReadString(r, element)
	return head, err
}

func writeNoteHead(w *xml.Encoder, name string, head *NoteHead) (err error) {
	var attrs []xml.Attr
	if head.Filled {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "filled"}, Value: "yes"})
	}
	if head.Parentheses {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "parentheses"}, Value: "yes"})
	}
	return WriteString(w, name, head.Value, attrs)
}

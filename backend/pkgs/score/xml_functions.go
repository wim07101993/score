package score

import (
	"encoding/xml"
	"fmt"
	"io"
)

func IterateOverTokens(r xml.TokenReader, h func(t xml.Token) (stop bool, err error)) error {
	for {
		t, err := r.Token()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		stop, err := h(t)
		if err != nil {
			return err
		}
		if stop {
			return nil
		}
	}
}

func WhenToken(
	t xml.Token,
	startElement func(element xml.StartElement) error,
	endElement func(element xml.EndElement) error,
	charData func(charData xml.CharData) error,
	comment func(comment xml.Comment) error,
	procInst func(procInst xml.ProcInst) error,
	directive func(directive xml.Directive) error,
) error {
	switch tp := t.(type) {
	case xml.StartElement:
		return startElement(t.(xml.StartElement))
	case xml.EndElement:
		return endElement(t.(xml.EndElement))
	case xml.CharData:
		return charData(t.(xml.CharData))
	case xml.Comment:
		return comment(t.(xml.Comment))
	case xml.ProcInst:
		return procInst(t.(xml.ProcInst))
	case xml.Directive:
		return directive(t.(xml.Directive))
	default:
		return fmt.Errorf("unknown xml token type %v (%v)", tp, t)
	}
}

func CharData(t xml.Token) (string, error) {
	switch t.(type) {
	case xml.CharData:
		return string(t.(xml.CharData)), nil
	default:
		return "", fmt.Errorf("unknown token (while expecting char-data) %v", t)
	}
}

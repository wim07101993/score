package musicxml

import (
	"encoding/xml"
	"fmt"
	"io"
	"strconv"
	"strings"
)

type UnexpectedTokenError struct {
	Element xml.StartElement
	Token   xml.Token
}

func (e *UnexpectedTokenError) Error() string {
	return fmt.Sprintf("unexpected token %v in element %v", e.Token, e.Element)
}

func IterateOverTokens(r xml.TokenReader, action func(t xml.Token) (stop bool, err error)) error {
	for {
		t, err := r.Token()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		stop, err := action(t)
		if err != nil {
			return err
		}
		if stop {
			return nil
		}
	}
}

func ReadObject(
	r xml.TokenReader,
	start xml.StartElement,
	onAttribute func(attr xml.Attr) error,
	onElement func(el xml.StartElement) error) error {

	if onAttribute != nil {
		for _, attr := range start.Attr {
			if err := onAttribute(attr); err != nil {
				return err
			}
		}
	}

	return IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.StartElement:
			if onElement == nil {
				err = IgnoreObject(r, e)
			} else {
				err = onElement(e)
			}
		case xml.EndElement:
			switch e.Name.Local {
			case start.Name.Local:
				stop = true
			default:
				err = fmt.Errorf("unexpected end element %v for start element %v", e.Name.Local, start.Name.Local)
			}
		case xml.CharData:
			data := string(e)
			if len(strings.Trim(data, " \n\r")) > 0 {
				return false, &UnexpectedTokenError{start, t}
			}
			return false, nil
		case xml.Comment, xml.ProcInst, xml.Directive:
			// IGNORE
			return false, nil
		default:
			return false, &UnexpectedTokenError{start, t}
		}
		return stop, err
	})
}

func IgnoreObject(r xml.TokenReader, start xml.StartElement) error {
	return ReadUntilClose(r, start)
}

func ReadUntilClose(r xml.TokenReader, start xml.StartElement) error {
	return IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.EndElement:
			if e.Name.Local == start.Name.Local {
				return true, nil
			}
		}
		return false, nil
	})
}

func ReadString(r xml.TokenReader, start xml.StartElement) (string, error) {
	t, err := r.Token()
	if err != nil {
		return "", nil
	}

	switch t.(type) {
	case xml.CharData:
		data := string(t.(xml.CharData))
		err := ReadUntilClose(r, start)
		return data, err
	default:
		return "", fmt.Errorf("unknown token (while expecting char-data) %t %v", t, t)
	}
}

func ReadInt(r xml.TokenReader, start xml.StartElement) (int, error) {
	s, err := ReadString(r, start)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(s)
}

func ReadFloat(r xml.TokenReader, start xml.StartElement) (float64, error) {
	s, err := ReadString(r, start)
	if err != nil {
		return 0, err
	}
	return strconv.ParseFloat(s, 64)
}

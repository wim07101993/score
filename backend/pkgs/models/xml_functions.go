package models

import (
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

func (p *MusicXmlParser) unknownElement(parent xml.StartElement, el xml.StartElement) {
	fmt.Printf("unknown element %v for %v\n", el.Name.Local, parent.Name.Local)
}

func (p *MusicXmlParser) unknownToken(parent xml.StartElement, t xml.Token) {
	fmt.Printf("unexpected token %v for %v\n", t, parent.Name.Local)
}

func (p *MusicXmlParser) unknownAttribute(parent xml.StartElement, attr xml.Attr) {
	fmt.Printf("unknown attribute %v for %v\n", attr.Name.Local, parent.Name.Local)
}

func (p *MusicXmlParser) IterateOverTokens(r xml.TokenReader, h func(t xml.Token) (stop bool, err error)) error {
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

func (p *MusicXmlParser) IterateOverElements(r xml.TokenReader, parent xml.StartElement, h func(el xml.StartElement) error) error {
	var startElement xml.StartElement
	return p.IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch el := t.(type) {
		case xml.StartElement:
			startElement = el
			//fmt.Println("parent:", parent.Name.Local, "\t start element: ", el.Name.Local)
			err := h(el)
			if err != nil {
				return false, err
			}
			return false, nil
		case xml.EndElement:
			switch el.Name.Local {
			case startElement.Name.Local:
				//fmt.Println("parent:", parent.Name.Local, "\t end element: ", el.Name.Local)
				startElement = xml.StartElement{}
				return false, nil
			case parent.Name.Local:
				//fmt.Println("parent:", parent.Name.Local, "\t end")
				return true, nil
			default:
				return false, nil
			}
		case xml.CharData:
			data := string(el)
			if len(strings.Trim(data, " \n\r")) > 0 {
				fmt.Printf("unexpected token %s for %v\n", t, parent.Name.Local)
			}
			return false, nil
		default:
			fmt.Printf("unexpected token %s for %v\n", t, parent.Name.Local)
			return false, nil
		}
	})
}

func (p *MusicXmlParser) CharData(t xml.Token) (string, error) {
	switch t.(type) {
	case xml.CharData:
		return string(t.(xml.CharData)), nil
	default:
		return "", fmt.Errorf("unknown token (while expecting char-data) %v", t)
	}
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"io"
	"log/slog"
	"strconv"
	"strings"
)

func (p *Parser) iterateOverTokens(action func(t xml.Token) (stop bool, err error)) error {
	for {
		t, err := p.Reader.Token()
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

func (p *Parser) readObject(
	start xml.StartElement,
	onAttribute func(attr xml.Attr) error,
	onElement func(el xml.StartElement) error) error {

	for _, attr := range start.Attr {
		if onAttribute == nil {
			p.unknownAttribute(start, attr)
		} else if err := onAttribute(attr); err != nil {
			return err
		}
	}

	return p.iterateOverTokens(func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.StartElement:
			if onElement == nil {
				p.unknownElement(start, e)
				err = p.ignoreObject(e)
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
				p.unexpectedToken(start, t)
			}
			return false, nil
		case xml.Comment:
			// IGNORE
		case xml.ProcInst:
			// IGNORE
		case xml.Directive:
			// IGNORE
		default:
			p.unexpectedToken(start, t)
		}
		return stop, err
	})
}

func (p *Parser) ignoreObject(start xml.StartElement) error {
	return p.readUntilClose(start)
}

func (p *Parser) readUntilClose(start xml.StartElement) error {
	return p.iterateOverTokens(func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.EndElement:
			if e.Name.Local == start.Name.Local {
				return true, nil
			}
		}
		return false, nil
	})
}

func (p *Parser) unknownElement(parent xml.StartElement, child xml.StartElement) {
	p.logger.Warn("unknown start element inside element",
		slog.Any("parent", parent),
		slog.Any("child", child))
}

func (p *Parser) unknownAttribute(parent xml.StartElement, attr xml.Attr) {
	p.logger.Warn("unknown attribute inside element",
		slog.Any("element", parent),
		slog.Any("attribute", attr))
}

func (p *Parser) unexpectedToken(parent xml.StartElement, t xml.Token) {
	p.logger.Warn("unexpected token inside element",
		slog.Any("element", parent),
		slog.Any("token", t))
}

func (p *Parser) readString(start xml.StartElement) (string, error) {
	t, err := p.Reader.Token()
	if err != nil {
		return "", nil
	}

	switch t.(type) {
	case xml.CharData:
		data := string(t.(xml.CharData))
		err := p.readUntilClose(start)
		return data, err
	default:
		return "", fmt.Errorf("unknown token (while expecting char-data) %v", t)
	}
}

func (p *Parser) readInt(start xml.StartElement) (int, error) {
	s, err := p.readString(start)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(s)
}

func (p *Parser) readFloat(start xml.StartElement) (float64, error) {
	s, err := p.readString(start)
	if err != nil {
		return 0, err
	}
	return strconv.ParseFloat(s, 64)
}

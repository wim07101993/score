package musicxml

import (
	"encoding/xml"
	"fmt"
	"io"
	"strings"
	"time"
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

// ReadObject reads the element that was just opened up to and including its
// end, handing each of its attributes to onAttribute and each of the elements
// in it to onElement.
//
// What a reader does not know is skipped rather than refused, and the readers
// built on this are written that way: an attribute nobody asked for is left
// alone, and an element nobody asked for is read past whole, children and all,
// with ReadUntilClose. This parser reads a handful of things out of a document
// to file it by — its title, who wrote it, what it is played on — and nothing
// else in it is any of its business. MusicXML has grown with every version, and
// every program that writes it puts in things of its own that the schema
// allows: MuseScore marks a score exported in concert pitch, Finale names its
// staff groups, and Sibelius links each part to a file of its own. Refusing a
// document over one of those refuses a perfectly good score for something
// nobody here would ever read.
//
// What is still refused is a document that is not well-formed — the decoder
// sees to that — and text where an element should be, which is not a document
// with something extra in it but a document that is wrong.
func ReadObject(
	r xml.TokenReader,
	start xml.StartElement,
	onAttribute func(attr xml.Attr) error,
	onElement func(el xml.StartElement) error) error {

	if onAttribute != nil {
		for _, attr := range start.Attr {
			if ignoreLayoutAttribute(attr) {
				continue
			}
			if err := onAttribute(attr); err != nil {
				return err
			}
		}
	}

	return IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.StartElement:
			if onElement == nil || ignoreLayoutElements(e) {
				err = ReadUntilClose(r, e)
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
			if len(strings.TrimSpace(data)) > 0 {
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

// ReadUntilClose reads past everything up to and including the end of the
// element that was just opened, whatever is in it.
//
// It counts how deep it is rather than stopping at the first end element with
// the right name: an element skipped because it is not known here may well hold
// one of the same name — a group in a group — and stopping at the inner one
// would leave the rest of the outer one to be read as if it were the parent's.
// The decoder has already made sure every end element matches its start, so
// counting is enough to tell which one closes this.
func ReadUntilClose(r xml.TokenReader, start xml.StartElement) error {
	depth := 0
	return IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch t.(type) {
		case xml.StartElement:
			depth++
		case xml.EndElement:
			if depth == 0 {
				return true, nil
			}
			depth--
		}
		return false, nil
	})
}

// ReadString reads the text of the element that was just opened, up to and
// including its end.
//
// The text is all of it, however it was written down. A CDATA section is text
// like any other — it is how a title with an ampersand in it can be written
// without escaping it — and the decoder hands it over as a piece of text of its
// own, so the pieces are put back together rather than the first one taken for
// the whole. A comment or a processing instruction in the middle of it is not
// part of the text, and is left out rather than ending it there.
//
// An element inside one that holds text is not something MusicXML ever does,
// and is refused.
func ReadString(r xml.TokenReader, start xml.StartElement) (string, error) {
	var text strings.Builder
	err := IterateOverTokens(r, func(t xml.Token) (stop bool, err error) {
		switch e := t.(type) {
		case xml.CharData:
			// A CharData is only good until the next token is read, so it is
			// copied out here rather than held on to.
			text.Write(e)
			return false, nil
		case xml.Comment, xml.ProcInst, xml.Directive:
			return false, nil
		case xml.EndElement:
			if e.Name.Local != start.Name.Local {
				return false, fmt.Errorf("unexpected end element %s while expecting %v", e.Name.Local, start.Name.Local)
			}
			return true, nil
		default:
			return false, &UnexpectedTokenError{start, t}
		}
	})
	if err != nil {
		return "", err
	}
	return text.String(), nil
}

func ReadTime(r xml.TokenReader, start xml.StartElement) (time.Time, error) {
	s, err := ReadString(r, start)
	if err != nil {
		return time.Time{}, err
	}
	return time.Parse("2006-01-02", s)
}

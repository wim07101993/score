package musicxml

import (
	"encoding/xml"
	"fmt"
)

type UnknownAttribute struct {
	Parent    xml.StartElement
	Attribute xml.Attr
}

func (e *UnknownAttribute) Error() string {
	return fmt.Sprintf("unknown attribute %v in element %v", e.Attribute, e.Parent)
}

type UnknownElement struct {
	Parent  xml.StartElement
	Element xml.StartElement
}

func (e *UnknownElement) Error() string {
	return fmt.Sprintf("unknown element %v in element %v", e.Element, e.Parent)
}

type FieldAlreadySet struct {
	Parent  xml.StartElement
	Element xml.StartElement
}

func (e *FieldAlreadySet) Error() string {
	return fmt.Sprintf("field %v in element %v already set", e.Element, e.Parent)
}

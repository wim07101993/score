package musicxml

import (
	"encoding/xml"
	"slices"
)

var layoutAttrs = []string{
	"print-object", "color",
	"default-x", "default-y", "relative-x", "relative-y",
	"valign", "halign", "width",
	"font-family", "font-style", "font-size", "font-weight",
	"placement", "justify", "spread",
	"bezier-x", "bezier-y", "bezier-x2", "bezier-y2",
}

var layoutElements = []string{
	"display-step", "display-octave", "part",
}

func ignoreLayoutAttribute(attr xml.Attr) bool {
	return slices.Contains(layoutAttrs, attr.Name.Local)
}

func ignoreLayoutElements(element xml.StartElement) bool {
	return slices.Contains(layoutElements, element.Name.Local)
}

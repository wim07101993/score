package musicxml

import (
	"encoding/xml"
	"io"
)

func ParseMusicXml(r io.Reader) (MusicDoc, error) {
	decoder := xml.NewDecoder(r)
	mdoc := MusicDoc{}
	err := decoder.Decode(&mdoc)
	return mdoc, err
}

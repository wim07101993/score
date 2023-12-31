package musicxml

import (
	"encoding/xml"
	"io"
)

func ParseMusicXml(r io.Reader) (*ScorePartwise, error) {
	decoder := xml.NewDecoder(r)
	mdoc := &ScorePartwise{}
	err := decoder.Decode(mdoc)
	return mdoc, err
}

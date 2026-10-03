package musicxml

import (
	"encoding/xml"
	"errors"
)

func DeserializeMusicXml(r xml.TokenReader) (score *ScorePartwise, err error) {
	root := xml.StartElement{Name: xml.Name{Local: "root"}}
	err = ReadObject(r, root,
		func(attr xml.Attr) error {
			return &UnknownAttribute{root, attr}
		},
		func(el xml.StartElement) (err error) {
			switch el.Name.Local {
			case "score-partwise":
				score, err = scorePartwise(r, el)
			default:
				// Unlike anywhere inside a score, an element nobody knows is
				// refused here: what is at the root says what kind of document
				// this is, and anything but a partwise score is either not
				// MusicXML at all or a kind of it this cannot read. Skipping it
				// would only turn a clear answer into "no score-partwise".
				err = &UnknownElement{root, el}
			}
			return err
		})
	if err != nil {
		return nil, err
	}
	if score == nil {
		return nil, errors.New("document does not contain a score-partwise element")
	}

	return score, nil
}

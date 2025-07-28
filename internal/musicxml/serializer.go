package musicxml

import (
	"encoding/xml"
)

func DeserializeMusicXml(r xml.TokenReader) (score *ScorePartwise, err error) {
	root := xml.StartElement{Name: xml.Name{Local: "root"}}
	score = &ScorePartwise{}
	err = ReadObject(r, root,
		func(attr xml.Attr) error {
			return &UnknownAttribute{root, attr}
		},
		func(el xml.StartElement) (err error) {
			switch el.Name.Local {
			case "score-partwise":
				score, err = scorePartwise(r, el)
			default:
				err = &UnknownElement{root, el}
			}
			return err
		})

	return score, err
}

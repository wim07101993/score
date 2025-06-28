package musicxml

import (
	"encoding/xml"
)

func SerializeMusixXml(w *xml.Encoder, music *ScorePartwise) (err error) {
	if err = writeHeaders(w); err != nil {
		return err
	}
	return WriteObject(w, "score-partwise",
		[]xml.Attr{
			{Name: xml.Name{Local: "version"}, Value: "4.0"},
		},
		func() error {
			return writeWork(w, "work", music.Work)
		},
		func() error {
			if music.MovementNumber == "" {
				return nil
			}
			return WriteString(w, "movement-number", music.MovementNumber, nil)
		},
		func() error {
			if music.MovementTitle == "" {
				return nil
			}
			return WriteString(w, "movement-title", music.MovementTitle, nil)
		},
		func() error {
			if music.Identification == nil {
				return nil
			}
			return writeIdentification(w, "identification", music.Identification)
		},
		func() error {
			if music.Defaults == nil {
				return nil
			}
			return writeDefaults(w, "defaults", music.Defaults)
		},
		func() error {
			return writePartList(w, "part-list", music.PartList)
		},
		func() error {
			for _, p := range music.Parts {
				if err = writePart(w, "part", p); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

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

func writeHeaders(w *xml.Encoder) (err error) {
	err = w.EncodeToken(xml.ProcInst{
		Target: "xml",
		Inst:   []byte(`version="1.0" encoding="UTF-8" standalone="no"`),
	})
	if err != nil {
		return err
	}

	if err = w.EncodeToken(xml.CharData("\n")); err != nil {
		return err
	}

	err = w.EncodeToken(xml.Directive(`DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd"`))
	if err != nil {
		return err
	}

	return w.EncodeToken(xml.CharData("\n"))
}

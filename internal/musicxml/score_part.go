package musicxml

import (
	"context"
	"encoding/xml"
	"log/slog"
)

type ScorePart struct {
	Id                  string
	Identification      *Identification
	Name                string
	NameDisplay         *DisplayName
	Abbreviation        string
	AbbreviationDisplay *DisplayName
	Instruments         []*Instrument
}

func readScorePart(r xml.TokenReader, element xml.StartElement) (part *ScorePart, err error) {
	part = &ScorePart{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				part.Id = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "identification":
				part.Identification, err = readIdentification(r, el)
			case "part-name":
				part.Name, err = ReadString(r, el)
			case "part-name-display":
				part.NameDisplay, err = readDisplayName(r, el)
			case "part-abbreviation":
				part.Abbreviation, err = ReadString(r, el)
			case "part-abbreviation-display":
				part.AbbreviationDisplay, err = readDisplayName(r, el)
			case "score-instrument":
				instr, err := readInstrument(r, el)
				if err != nil {
					return err
				}
				part.Instruments = append(part.Instruments, instr)
			case "midi-instrument":
				slog.Log(context.Background(), slog.LevelWarn, "midi instruments are not supported right now, we might in the future")
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return part, err
}

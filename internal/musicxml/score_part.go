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

func writeScorePart(w *xml.Encoder, name string, part *ScorePart) (err error) {
	def := ScorePart{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "id"}, Value: part.Id},
		},
		func() error {
			if part.Identification != nil {
				return writeIdentification(w, "identification", part.Identification)
			}
			return nil
		},
		func() error {
			return WriteString(w, "part-name", part.Name, nil)
		},
		func() error {
			if part.NameDisplay != nil && part.Name != part.NameDisplay.String() {
				return writeDisplayName(w, "part-name-display", part.NameDisplay)
			}
			return nil
		},
		func() error {
			if part.Abbreviation != def.Abbreviation {
				return WriteString(w, "part-abbreviation", part.Abbreviation, nil)
			}
			return nil
		},
		func() error {
			if part.AbbreviationDisplay != nil && part.Abbreviation != part.AbbreviationDisplay.String() {
				return writeDisplayName(w, "part-abbreviation-display", part.AbbreviationDisplay)
			}
			return nil
		},
		func() error {
			for _, instr := range part.Instruments {
				if err = writeInstrument(w, "score-instrument", instr); err != nil {
					return err
				}
			}
			return nil
		})
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"slices"
	"strconv"
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

func scorePartwise(r xml.TokenReader, element xml.StartElement) (score *ScorePartwise, err error) {
	score = &ScorePartwise{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "version":
				return nil
			default:
				return &UnknownAttribute{element, attr}
			}
		},
		func(el xml.StartElement) (err error) {
			switch el.Name.Local {
			case "work":
				score.Work, err = work(r, el)
			case "identification":
				score.Identification, err = identification(r, el)
			case "defaults":
				score.Defaults, err = defaults(r, el)
			case "credit":
				err = ReadUntilClose(r, el)
			case "part-list":
				score.PartList, err = partList(r, el)
			case "part":
				part, err := part(r, el)
				if err != nil {
					return err
				}
				score.Parts = append(score.Parts, part)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return score, err
}

func part(r xml.TokenReader, element xml.StartElement) (part *Part, err error) {
	part = &Part{}
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
			case "measure":
				measure, err := measure(r, el)
				if err != nil {
					return err
				}
				part.Measures = append(part.Measures, measure)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return part, err
}

func measure(r xml.TokenReader, element xml.StartElement) (measure *Measure, err error) {
	measure = &Measure{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				measure.Number = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "attributes":
				measure.Attributes, err = measureAttributes(r, el)
			case "print":
				err = ReadUntilClose(r, el)
			case "direction":
				direction, err := direction(r, el)
				if err != nil {
					return err
				}
				measure.Directions = append(measure.Directions, direction)
			case "note":
				note, err := note(r, el)
				if err != nil {
					return err
				}
				measure.Notes = append(measure.Notes, note)
			case "barline":
				barline, err := barline(r, el)
				if err != nil {
					return err
				}
				measure.Barlines = append(measure.Barlines, barline)
			case "harmony":
				harmony, err := harmony(r, el)
				if err != nil {
					return err
				}
				measure.Harmonies = append(measure.Harmonies, harmony)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return measure, err
}

func harmony(r xml.TokenReader, element xml.StartElement) (harmony *Harmony, err error) {
	harmony = &Harmony{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "root":
				harmony.Root, err = harmonyRoot(r, el)
			case "kind":
				harmony.Kind, err = ReadString(r, el)
			case "staff":
				harmony.Staff, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return harmony, err
}

func harmonyRoot(r xml.TokenReader, element xml.StartElement) (root *HarmonyRoot, err error) {
	root = &HarmonyRoot{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "root-step":
				root.Step, err = ReadString(r, el)
			case "root-alter":
				root.Alter, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return root, err
}

func barline(r xml.TokenReader, element xml.StartElement) (barline *Barline, err error) {
	barline = &Barline{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "location":
				barline.Location = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "bar-style":
				barline.Style, err = ReadString(r, el)
			case "repeat":
				barline.Repeat, err = repeat(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return barline, err
}

func repeat(r xml.TokenReader, element xml.StartElement) (repeat *Repeat, err error) {
	repeat = &Repeat{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "direction":
				repeat.Direction = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return repeat, err
}

func note(r xml.TokenReader, element xml.StartElement) (note *Note, err error) {
	note = &Note{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "pitch":
				note.Pitch, err = pitch(r, el)
			case "duration":
				note.Duration, err = ReadInt(r, el)
			case "instrument":
				note.Instrument, err = instrumentReference(r, el)
			case "voice":
				note.Voice, err = ReadInt(r, el)
			case "type":
				note.Type, err = ReadString(r, el)
			case "stem":
				note.Stem, err = ReadString(r, el)
			case "staff":
				note.Staff, err = ReadInt(r, el)
			case "beam":
				beam, err := beam(r, el)
				if err != nil {
					return nil
				}
				note.Beams = append(note.Beams, beam)
			case "lyric":
				lyric, err := lyric(r, el)
				if err != nil {
					return err
				}
				note.Lyrics = append(note.Lyrics, lyric)
			case "dot":
				note.dotCount++
				err = ReadUntilClose(r, el)
			case "rest":
				note.Rest, err = rest(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return note, err
}

func rest(r xml.TokenReader, element xml.StartElement) (rest *Rest, err error) {
	rest = &Rest{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "measure":
				rest.Measure = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return rest, err
}

func lyric(r xml.TokenReader, element xml.StartElement) (lyric *Lyric, err error) {
	lyric = &Lyric{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				lyric.Number = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "syllabic":
				lyric.Syllabic, err = ReadString(r, el)
			case "text":
				lyric.Text, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return lyric, err
}

func instrumentReference(r xml.TokenReader, element xml.StartElement) (id string, err error) {
	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "id":
			id = attr.Value
		default:
			return "", &UnknownAttribute{element, attr}
		}
	}
	return id, ReadUntilClose(r, element)
}

func beam(r xml.TokenReader, element xml.StartElement) (beam *Beam, err error) {
	beam = &Beam{}

	token, err := r.Token()
	if err != nil {
		return beam, err
	}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "number":
			beam.Number, err = strconv.Atoi(attr.Value)
			if err != nil {
				return beam, err
			}
		default:
			return beam, &UnknownAttribute{element, attr}
		}
	}

	switch el := token.(type) {
	case xml.CharData:
		beam.Type = string(el)
	default:
		return beam, &UnexpectedTokenError{element, token}
	}

	err = ReadUntilClose(r, element)
	return beam, err
}

func pitch(r xml.TokenReader, element xml.StartElement) (pitch *Pitch, err error) {
	pitch = &Pitch{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "step":
				pitch.Step, err = ReadString(r, el)
			case "octave":
				pitch.Octave, err = ReadInt(r, el)
			case "alter":
				pitch.Alter, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return pitch, err
}

func direction(r xml.TokenReader, element xml.StartElement) (direction *Direction, err error) {
	direction = &Direction{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "direction-type":
				tp, err := directionType(r, el)
				if err != nil {
					return err
				}
				direction.DirectionTypes = append(direction.DirectionTypes, tp)
			case "voice":
				direction.Voice, err = ReadInt(r, el)
			case "staff":
				direction.Staff, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return direction, err
}

func directionType(r xml.TokenReader, element xml.StartElement) (tp DirectionType, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "metronome":
				tp, err = metronome(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return tp, err
}

func metronome(r xml.TokenReader, element xml.StartElement) (metronome *Metronome, err error) {
	metronome = &Metronome{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "beat-unit":
				metronome.BeatUnit, err = ReadString(r, el)
			case "per-minute":
				metronome.PerMinute, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return metronome, err
}

func measureAttributes(r xml.TokenReader, element xml.StartElement) (attr *MeasureAttributes, err error) {
	attr = &MeasureAttributes{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "divisions":
				attr.Divisions, err = ReadInt(r, el)
			case "key":
				attr.Key, err = key(r, el)
			case "time":
				attr.Time, err = timeSignature(r, el)
			case "staves":
				attr.Staves, err = ReadInt(r, el)
			case "clef":
				attr.Clef, err = clef(r, el)
			case "staff-details":
				attr.StaffDetails, err = staffDetails(r, el)
			case "transpose":
				attr.Transpose, err = transpose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return attr, err
}

func transpose(r xml.TokenReader, element xml.StartElement) (transpose *Transpose, err error) {
	transpose = &Transpose{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "diatonic":
				transpose.Diatonic, err = ReadInt(r, el)
			case "chromatic":
				transpose.Chromatic, err = ReadInt(r, el)
			case "octave-change":
				transpose.OctaveChange, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return transpose, err
}

func staffDetails(r xml.TokenReader, element xml.StartElement) (staff *StaffDetails, err error) {
	staff = &StaffDetails{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				staff.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})

	return staff, err
}

func clef(r xml.TokenReader, element xml.StartElement) (clef *Clef, err error) {
	clef = &Clef{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				clef.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "sign":
				clef.Sign, err = ReadString(r, el)
			case "line":
				clef.Line, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return clef, err
}

func timeSignature(r xml.TokenReader, element xml.StartElement) (time *TimeSignature, err error) {
	time = &TimeSignature{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "symbol":
				time.Symbol = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "beats":
				time.Beats, err = ReadInt(r, el)
			case "beat-type":
				time.BeatType, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return time, err
}

func key(r xml.TokenReader, element xml.StartElement) (key *Key, err error) {
	key = &Key{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "fifths":
				key.Fifths, err = ReadInt(r, el)
			case "mode":
				key.Mode, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return key, err
}

func partList(r xml.TokenReader, element xml.StartElement) (list []PartListItem, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			var item interface{}
			switch el.Name.Local {
			case "part-group":
				item, err = partGroup(r, el)
			case "score-part":
				item, err = scorePart(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			if err == nil {
				list = append(list, item)
			}
			return err
		})
	return list, err
}

func scorePart(r xml.TokenReader, element xml.StartElement) (part *ScorePart, err error) {
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
				part.Identification, err = identification(r, el)
			case "part-name":
				part.Name, err = ReadString(r, el)
			case "part-name-display":
				part.NameDisplay, err = ReadString(r, el)
			case "part-abbreviation":
				part.Abbreviation, err = ReadString(r, el)
			case "part-abbreviation-display":
				part.AbbreviationDisplay, err = ReadString(r, el)
			case "score-instrument":
				part.Instrument, err = instrument(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return part, err
}

func instrument(r xml.TokenReader, element xml.StartElement) (instr *Instrument, err error) {
	instr = &Instrument{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "id":
				instr.Id = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "instrument-name":
				instr.Name, err = ReadString(r, el)
			case "instrument-sound":
				instr.Sound, err = ReadString(r, el)
			case "solo":
				instr.IsSolo = true
				err = ReadUntilClose(r, el)
			case "virtual-instrument":
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return instr, err
}

func partGroup(r xml.TokenReader, element xml.StartElement) (group *PartGroup, err error) {
	group = &PartGroup{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				group.Type = attr.Value
			case "number":
				group.Number, err = strconv.Atoi(attr.Value)
			default:
				err = &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "group-symbol":
				group.Symbol, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return group, err
}

func defaults(r xml.TokenReader, element xml.StartElement) (defaults *Defaults, err error) {
	defaults = &Defaults{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "scaling", "page-layout", "system-layout", "appearance",
				"music-font", "word-font", "lyric-font":
				return ReadUntilClose(r, el)
			case "lyric-language":
				defaults.LyricLanguage, err = language(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return defaults, err
}

func language(r xml.TokenReader, element xml.StartElement) (lang string, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "lang":
				lang = attr.Value
			default:
				err = &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return lang, err
}

func identification(r xml.TokenReader, element xml.StartElement) (id *Identification, err error) {
	id = &Identification{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "creator":
				creator, err := creator(r, el)
				if err != nil {
					return err
				}
				id.Creators = append(id.Creators, creator)
			case "encoding":
				id.Encoding, err = encoding(r, el)
			case "miscellaneous":
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return id, err
}

func creator(r xml.TokenReader, element xml.StartElement) (creator *Creator, err error) {
	creator = &Creator{}

	token, err := r.Token()
	if err != nil {
		return creator, err
	}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "type":
			creator.Type = attr.Value
		default:
			return creator, &UnknownAttribute{element, attr}
		}
	}

	switch el := token.(type) {
	case xml.CharData:
		creator.Value = string(el)
	default:
		return creator, &UnexpectedTokenError{element, token}
	}

	err = ReadUntilClose(r, element)
	return creator, err
}

func work(r xml.TokenReader, element xml.StartElement) (work *Work, err error) {
	work = &Work{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "work-title":
				work.Title, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return work, err
}

func encoding(r xml.TokenReader, element xml.StartElement) (encoding *Encoding, err error) {
	encoding = &Encoding{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "encoding-date":
				encoding.Date, err = ReadTime(r, el)
			case "encoder", "software", "encoding-description", "supports":
				err = ReadUntilClose(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return encoding, err
}

var layoutAttrs = []string{
	"print-object", "color",
	"default-x", "default-y", "width",
	"font-family", "font-style", "font-size", "font-weight",
}

func ignoreLayoutAttribute(attr xml.Attr) bool {
	return slices.Contains(layoutAttrs, attr.Name.Local)
}

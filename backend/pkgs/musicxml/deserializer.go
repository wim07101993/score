package musicxml

import (
	"encoding/xml"
	"fmt"
	"slices"
	"strconv"
	"time"
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
				if attr.Value != "4.0" && attr.Value != "3.0" {
					return fmt.Errorf("expected musicxml version 4.0")
				}
				return nil
			default:
				return &UnknownAttribute{element, attr}
			}
		},
		func(el xml.StartElement) (err error) {
			switch el.Name.Local {
			case "work":
				if score.Work != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Work, err = work(r, el)
			case "movement-number":
				if score.MovementNumber != "" {
					return &FieldAlreadySet{element, el}
				}
				score.MovementNumber, err = ReadString(r, el)
			case "movement-title":
				if score.MovementTitle != "" {
					return &FieldAlreadySet{element, el}
				}
				score.MovementTitle, err = ReadString(r, el)
			case "identification":
				if score.Identification != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Identification, err = identification(r, el)
			case "defaults":
				if score.Defaults != nil {
					return &FieldAlreadySet{element, el}
				}
				score.Defaults, err = defaults(r, el)
			case "credit":
				err = ReadUntilClose(r, el) // IGNORE credits
			case "part-list":
				if score.PartList != nil {
					return &FieldAlreadySet{element, el}
				}
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
			var item MeasureElement
			switch el.Name.Local {
			case "attributes":
				item.Attributes, err = measureAttributes(r, el)
			case "print":
				err = ReadUntilClose(r, el)
			case "direction":
				item.Direction, err = direction(r, el)
			case "note":
				item.Note, err = note(r, el)
			case "barline":
				item.Barline, err = barline(r, el)
			case "harmony":
				item.Harmony, err = harmony(r, el)
			case "backup":
				item.Backup, err = backup(r, el)
			case "forward":
				item.Forward, err = forward(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			if err != nil {
				return err
			}
			measure.Elements = append(measure.Elements, item)
			return nil
		})

	return measure, err
}

func forward(r xml.TokenReader, element xml.StartElement) (forward *Forward, err error) {
	forward = &Forward{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "duration":
				if forward.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				forward.Duration, err = ReadFloat32(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return forward, err
}

func backup(r xml.TokenReader, element xml.StartElement) (backup *Backup, err error) {
	backup = &Backup{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "duration":
				if backup.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				backup.Duration, err = ReadFloat32(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return backup, err
}

func harmony(r xml.TokenReader, element xml.StartElement) (harmony *Harmony, err error) {
	def := Harmony{}
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
				if harmony.Root != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Root, err = harmonyRoot(r, el)
			case "kind":
				if harmony.Kind != def.Kind {
					return &FieldAlreadySet{element, el}
				}
				harmony.Kind, err = ReadString(r, el)
			case "staff":
				if harmony.Staff != def.Staff {
					return &FieldAlreadySet{element, el}
				}
				harmony.Staff, err = ReadInt(r, el)
			case "bass":
				if harmony.Bass != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Bass, err = bass(r, el)
			case "degree":
				degree, err := degree(r, el)
				if err != nil {
					return err
				}
				harmony.Degrees = append(harmony.Degrees, degree)
			case "frame":
				if harmony.Frame != nil {
					return &FieldAlreadySet{element, el}
				}
				harmony.Frame, err = frame(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return harmony, err
}

func frame(r xml.TokenReader, element xml.StartElement) (frame *Frame, err error) {
	frame = &Frame{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "frame-strings":
				if frame.Strings != 0 {
					return &FieldAlreadySet{element, el}
				}
				frame.Strings, err = ReadInt(r, el)
			case "frame-frets":
				if frame.Frets != 0 {
					return &FieldAlreadySet{element, el}
				}
				frame.Frets, err = ReadInt(r, el)
			case "first-fret":
				if frame.FirstFret != nil {
					return &FieldAlreadySet{element, el}
				}
				frame.FirstFret, err = firstFret(r, el)
			case "frame-note":
				note, err := frameNote(r, el)
				if err != nil {
					return err
				}
				frame.Notes = append(frame.Notes, note)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return frame, err
}

func frameNote(r xml.TokenReader, element xml.StartElement) (note *FrameNote, err error) {
	note = &FrameNote{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "string":
				if note.String != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.String, err = ReadInt(r, el)
			case "fret":
				if note.Fret != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Fret, err = ReadInt(r, el)
			case "fingering":
				if note.Fingering != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Fingering, err = fingering(r, el)
			case "barre":
				if note.Barre != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Barre, err = barre(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return note, err
}

func barre(r xml.TokenReader, element xml.StartElement) (barre *Barre, err error) {
	barre = &Barre{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				barre.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})

	return barre, err
}

func fingering(r xml.TokenReader, element xml.StartElement) (f *Fingering, err error) {
	f = &Fingering{}

	for _, attr := range element.Attr {
		if ignoreLayoutAttribute(attr) {
			continue
		}
		switch attr.Name.Local {
		case "substitution":
			f.Substitution = attr.Value == "yes"
		case "alternate":
			f.Alternate = attr.Value == "yes"
		default:
			return f, &UnknownAttribute{element, attr}
		}
	}

	f.Value, err = ReadString(r, element)
	return f, err
}

func firstFret(r xml.TokenReader, element xml.StartElement) (fret *FirstFret, err error) {
	fret = &FirstFret{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "text":
			fret.Text = attr.Value
		case "location":
			fret.Location = attr.Value
		default:
			return fret, &UnknownAttribute{element, attr}
		}
	}

	fret.Value, err = ReadInt(r, element)
	return fret, err
}

func degree(r xml.TokenReader, element xml.StartElement) (degree *Degree, err error) {
	degree = &Degree{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "degree-alter":
				if degree.Alter != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Alter, err = degreeAlter(r, el)
			case "degree-type":
				if degree.Type != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Type, err = degreeType(r, el)
			case "degree-value":
				if degree.Value != nil {
					return &FieldAlreadySet{element, el}
				}
				degree.Value, err = degreeValue(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return degree, err
}

func degreeValue(r xml.TokenReader, element xml.StartElement) (value *DegreeValue, err error) {
	value = &DegreeValue{}

	for _, attr := range element.Attr {
		if ignoreLayoutAttribute(attr) {
			continue
		}
		switch attr.Name.Local {
		case "text":
			value.Text = attr.Value
		case "symbol":
			value.Symbol = attr.Value
		default:
			return value, &UnknownAttribute{element, attr}
		}
	}

	value.Value, err = ReadInt(r, element)

	return value, err
}

func degreeType(r xml.TokenReader, element xml.StartElement) (tp *DegreeType, err error) {
	tp = &DegreeType{}

	for _, attr := range element.Attr {
		if ignoreLayoutAttribute(attr) {
			continue
		}
		switch attr.Name.Local {
		case "text":
			tp.Text = attr.Value
		default:
			return tp, &UnknownAttribute{element, attr}
		}
	}

	tp.Value, err = ReadString(r, element)

	return tp, err
}

func degreeAlter(r xml.TokenReader, element xml.StartElement) (alter *DegreeAlter, err error) {
	alter = &DegreeAlter{}

	for _, attr := range element.Attr {
		if ignoreLayoutAttribute(attr) {
			continue
		}
		switch attr.Name.Local {
		case "plus-minus":
			alter.PlusMinus = attr.Value == "yes"
		default:
			return alter, &UnknownAttribute{element, attr}
		}
	}

	alter.Value, err = ReadFloat32(r, element)

	return alter, err
}

func bass(r xml.TokenReader, element xml.StartElement) (bass *Bass, err error) {
	bass = &Bass{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "bass-step":
				if bass.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				bass.Step, err = ReadString(r, el)
			case "bass-alter":
				if bass.Alter != "" {
					return &FieldAlreadySet{element, el}
				}
				bass.Alter, err = ReadString(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return bass, err
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
				if root.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				s, err := ReadString(r, el)
				if err != nil {
					return err
				}
				root.Step = Step(s)
			case "root-alter":
				if root.Alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				root.Alter, err = ReadFloat32(r, el)
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
				if barline.Style != "" {
					return &FieldAlreadySet{element, el}
				}
				barline.Style, err = ReadString(r, el)
			case "ending":
				if barline.Ending != nil {
					return &FieldAlreadySet{element, el}
				}
				barline.Ending, err = ending(r, el)
			case "repeat":
				if barline.Repeat != nil {
					return &FieldAlreadySet{element, el}
				}
				barline.Repeat, err = repeat(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return barline, err
}

func ending(r xml.TokenReader, element xml.StartElement) (ending *Ending, err error) {
	ending = &Ending{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				ending.Number = attr.Value
			case "type":
				ending.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return ending, err
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
			case "chord":
				if note.IsChord {
					return &FieldAlreadySet{element, el}
				}
				note.IsChord = true
				err = ReadUntilClose(r, el)
			case "pitch":
				if note.Pitch != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Pitch, err = pitch(r, el)
			case "duration":
				if note.Duration != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Duration, err = ReadInt(r, el)
			case "instrument":
				instrument, err := instrumentReference(r, el)
				if err != nil {
					return err
				}
				note.Instruments = append(note.Instruments, instrument)
			case "voice":
				if note.Voice != 0 {
					return &FieldAlreadySet{element, el}
				}
				note.Voice, err = ReadInt(r, el)
			case "type":
				if note.Type != "" {
					return &FieldAlreadySet{element, el}
				}
				note.Type, err = ReadString(r, el)
			case "stem":
				if note.Stem != "" {
					return &FieldAlreadySet{element, el}
				}
				note.Stem, err = ReadString(r, el)
			case "staff":
				if note.Staff != 0 {
					return &FieldAlreadySet{element, el}
				}
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
				if note.Rest != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Rest, err = rest(r, el)
			case "tie":
				tie, err := tie(r, el)
				if err != nil {
					return err
				}
				note.Ties = append(note.Ties, tie)
			case "notations":
				notation, err := notation(r, el)
				if err != nil {
					return err
				}
				note.Notations = append(note.Notations, notation)
			case "accidental":
				accidental, err := accidental(r, el)
				if err != nil {
					return err
				}
				note.Accidentals = append(note.Accidentals, accidental)
			case "time-modification":
				mod, err := timeModification(r, el)
				if err != nil {
					return err
				}
				note.TimeModifications = append(note.TimeModifications, mod)
			case "notehead":
				if note.Head != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Head, err = noteHead(r, el)
			case "cue":
				if note.Cue {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				note.Cue = true
			case "grace":
				if note.Grace != nil {
					return &FieldAlreadySet{element, el}
				}
				note.Grace, err = grace(r, el)
			case "unpitched":
				if note.IsUnpitched {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				note.IsUnpitched = true
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return note, err
}

func grace(r xml.TokenReader, element xml.StartElement) (grace *Grace, err error) {
	grace = &Grace{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "slash":
				grace.Slash = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return grace, err
}

func noteHead(r xml.TokenReader, element xml.StartElement) (head *NoteHead, err error) {
	head = &NoteHead{}
	for _, attr := range element.Attr {
		if ignoreLayoutAttribute(attr) {
			continue
		}
		switch attr.Name.Local {
		case "filled":
			head.Filled = attr.Value == "yes"
		case "parentheses":
			head.Parentheses = attr.Value == "yes"
		default:
			return head, &UnknownAttribute{element, attr}
		}
	}

	head.Value, err = ReadString(r, element)
	return head, err
}

func timeModification(r xml.TokenReader, element xml.StartElement) (mod *TimeModification, err error) {
	mod = &TimeModification{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "actual-notes":
				if mod.ActualNotes != 0 {
					return &FieldAlreadySet{element, el}
				}
				mod.ActualNotes, err = ReadInt(r, el)
			case "normal-notes":
				if mod.NormalNotes != 0 {
					return &FieldAlreadySet{element, el}
				}
				mod.NormalNotes, err = ReadInt(r, el)
			case "normal-type":
				tp, err := ReadString(r, el)
				if err != nil {
					return err
				}
				mod.Items = append(mod.Items, TimeModificationItem{NormalType: tp})
			case "normal-dot":
				err = ReadUntilClose(r, el)
				mod.Items = append(mod.Items, TimeModificationItem{HasDot: true})
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return mod, err
}

func accidental(r xml.TokenReader, element xml.StartElement) (acc *Accidental, err error) {
	acc = &Accidental{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		default:
			return acc, &UnknownAttribute{element, attr}
		}
	}

	acc.Value, err = ReadString(r, element)
	return acc, err
}

func notation(r xml.TokenReader, element xml.StartElement) (notation *Notation, err error) {
	notation = &Notation{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tied":
				tie, err := tied(r, el)
				if err != nil {
					return err
				}
				notation.Ties = append(notation.Ties, tie)
			case "slur":
				slur, err := slur(r, el)
				if err != nil {
					return err
				}
				notation.Slurs = append(notation.Slurs, slur)
			case "tuplet":
				tuplet, err := tuplet(r, el)
				if err != nil {
					return err
				}
				notation.Tuplets = append(notation.Tuplets, tuplet)
			case "fermata":
				fermata, err := fermata(r, el)
				if err != nil {
					return err
				}
				notation.Fermatas = append(notation.Fermatas, fermata)
			case "dynamics":
				dynamic, err := dynamic(r, el)
				if err != nil {
					return err
				}
				notation.Dynamics = append(notation.Dynamics, dynamic)
			case "articulations":
				articulations, err := articulations(r, el)
				if err != nil {
					return err
				}
				notation.Articulations = append(notation.Articulations, articulations)
			case "slide":
				slide, err := slide(r, el)
				if err != nil {
					return err
				}
				notation.Slides = append(notation.Slides, slide)
			case "arpeggiate":
				apr, err := arpeggiate(r, el)
				if err != nil {
					return err
				}
				notation.Arpeggiate = append(notation.Arpeggiate, apr)
			case "technical":
				tech, err := technical(r, el)
				if err != nil {
					return err
				}
				notation.Technical = append(notation.Technical, tech)
			case "glissando":
				glissando, err := glissando(r, el)
				if err != nil {
					return err
				}
				notation.Glissandos = append(notation.Glissandos, glissando)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return notation, err
}

func glissando(r xml.TokenReader, element xml.StartElement) (glissando *Glissando, err error) {
	glissando = &Glissando{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				glissando.Type = attr.Value
			case "number":
				num, err := strconv.Atoi(attr.Value)
				if err != nil {
					return err
				}
				glissando.Number = num
			case "line-type":
				glissando.LineType = attr.Value
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return glissando, err
}

func technical(r xml.TokenReader, element xml.StartElement) (tech *Technical, err error) {
	tech = &Technical{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "fret":
				if tech.Fret != 0 {
					return &FieldAlreadySet{element, el}
				}
				tech.Fret, err = ReadInt(r, el)
			case "string":
				if tech.String != 0 {
					return &FieldAlreadySet{element, el}
				}
				tech.String, err = ReadInt(r, el)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tech, err
}

func arpeggiate(r xml.TokenReader, element xml.StartElement) (apr *Arpeggiate, err error) {
	apr = &Arpeggiate{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return apr, err
}

func slide(r xml.TokenReader, element xml.StartElement) (slide *Slide, err error) {
	slide = &Slide{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				slide.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return slide, err
}

func articulations(r xml.TokenReader, element xml.StartElement) (art *Articulations, err error) {
	art = &Articulations{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tenuto":
				if art.Tenuto {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Tenuto = true
			case "staccato":
				if art.Staccato {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Staccato = true
			case "breath-mark":
				if art.BreathMark {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.BreathMark = true
			case "accent":
				if art.Accent {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				art.Accent = true
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return art, err
}

func fermata(r xml.TokenReader, element xml.StartElement) (fermata *Fermata, err error) {
	fermata = &Fermata{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "type":
			fermata.IsInverted = attr.Value == "inverted"
		default:
			return fermata, &UnknownAttribute{element, attr}
		}
	}

	val, err := ReadString(r, element)
	fermata.Shape = val

	return fermata, err
}

func tuplet(r xml.TokenReader, element xml.StartElement) (tuplet *Tuplet, err error) {
	tuplet = &Tuplet{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "type":
				tuplet.Type = attr.Value
			case "number":
				n, err := strconv.Atoi(attr.Value)
				if err != nil {
					return err
				}
				tuplet.Number = n
			case "bracket":
				tuplet.Bracket = attr.Value == "yes"
			case "show-number":
				tuplet.ShowNumber = attr.Value
			case "show-type":
				tuplet.ShowType = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuplet-actual":
				val, err := tupletPortion(r, el)
				if err != nil {
					return err
				}
				tuplet.Values = append(tuplet.Values, TupletValue{Actual: val})
			case "tuplet-normal":
				val, err := tupletPortion(r, el)
				if err != nil {
					return err
				}
				tuplet.Values = append(tuplet.Values, TupletValue{Normal: val})
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tuplet, err
}

func tupletPortion(r xml.TokenReader, element xml.StartElement) (portion *TupletPortion, err error) {
	portion = &TupletPortion{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuplet-number":
				if portion.Number != 0 {
					return &FieldAlreadySet{element, el}
				}
				portion.Number, err = ReadInt(r, el)
			case "tuplet-type":
				if portion.Type != "" {
					return &FieldAlreadySet{element, el}
				}
				portion.Type, err = ReadString(r, el)
			case "tuplet-dot":
				err = ReadUntilClose(r, el)
				portion.DotCount++
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return portion, err
}

func slur(r xml.TokenReader, element xml.StartElement) (slur *Slur, err error) {
	slur = &Slur{Number: 1}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "orientation":
				slur.Orientation = attr.Value
			case "type":
				slur.Type = attr.Value
			case "number":
				slur.Number, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return slur, err
}

func tied(r xml.TokenReader, element xml.StartElement) (tied *Tied, err error) {
	tied = &Tied{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "orientation":
				tied.Orientation = attr.Value
			case "type":
				tied.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return tied, err
}

func tie(r xml.TokenReader, element xml.StartElement) (tie *Tie, err error) {
	tie = &Tie{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				tie.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return tie, err
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
				if lyric.Syllabic != "" {
					return &FieldAlreadySet{element, el}
				}
				lyric.Syllabic, err = ReadString(r, el)
			case "text":
				if lyric.Text != "" {
					return &FieldAlreadySet{element, el}
				}
				lyric.Text, err = ReadString(r, el)
			case "extend":
				if lyric.Extend != nil {
					return &FieldAlreadySet{element, el}
				}
				lyric.Extend, err = extend(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return lyric, err
}

func extend(r xml.TokenReader, element xml.StartElement) (extend *Extend, err error) {
	extend = &Extend{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "type":
				extend.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {

			return &UnknownElement{element, el}
		})
	return extend, err
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
	beam = &Beam{Number: 1}

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

	beam.Type, err = ReadString(r, element)
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
				if pitch.Step != "" {
					return &FieldAlreadySet{element, el}
				}
				s, err := ReadString(r, el)
				if err != nil {
					return err
				}
				pitch.Step = Step(s)
			case "octave":
				if pitch.Octave != 0 {
					return &FieldAlreadySet{element, el}
				}
				pitch.Octave, err = ReadInt(r, el)
			case "alter":
				if pitch.Alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				pitch.Alter, err = ReadFloat32(r, el)
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
			switch attr.Name.Local {
			case "directive":
				direction.IsDirective = attr.Value == "yes"
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
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
				if direction.Voice != "" {
					return &FieldAlreadySet{element, el}
				}
				direction.Voice, err = ReadString(r, el)
			case "staff":
				if direction.Staff != 0 {
					return &FieldAlreadySet{element, el}
				}
				direction.Staff, err = ReadInt(r, el)
			case "offset":
				if direction.Offset != nil {
					return &FieldAlreadySet{element, el}
				}
				direction.Offset, err = offset(r, el)
			case "sound":
				if direction.Sound != nil {
					return &FieldAlreadySet{element, el}
				}
				direction.Sound, err = sound(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return direction, err
}

func sound(r xml.TokenReader, element xml.StartElement) (sound *Sound, err error) {
	sound = &Sound{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "tocoda":
				sound.ToCoda = attr.Value
			case "time-only":
				sound.TimeOnly = attr.Value
			case "tempo":
				tempo, err := strconv.ParseFloat(attr.Value, 32)
				sound.Tempo = float32(tempo)
				return err
			case "dynamics":
				dynamics, err := strconv.ParseFloat(attr.Value, 32)
				sound.Dynamics = float32(dynamics)
				return err
			case "dacapo":
				sound.DaCapo = attr.Value == "yes"
			case "segno":
				sound.Segno = attr.Value == "yes"
			case "dalsegno":
				sound.DalSegno = attr.Value == "yes"
			case "coda":
				sound.Coda = attr.Value
			case "divisions":
				divisions, err := strconv.ParseFloat(attr.Value, 32)
				sound.Divisions = float32(divisions)
				return err
			case "forward-repeat":
				sound.ForwardRepeat = attr.Value == "yes"
			case "fine":
				sound.Fine = attr.Value
			case "pizzicato":
				sound.Pizzicato = attr.Value == "yes"
			case "pan":
				pan, err := strconv.ParseFloat(attr.Value, 32)
				sound.Pan = float32(pan)
				return err
			case "elevation":
				elevation, err := strconv.ParseFloat(attr.Value, 32)
				sound.Elevation = float32(elevation)
				return err
			case "damper-pedal":
				sound.DamperPedal = attr.Value
			case "soft-pedal":
				sound.DamperPedal = attr.Value
			case "sostenuto-pedal":
				sound.SostenutoPedal = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "offset":
				if sound.Offset != nil {
					return &FieldAlreadySet{element, el}
				}
				sound.Offset, err = offset(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return sound, err
}

func offset(r xml.TokenReader, element xml.StartElement) (offset *Offset, err error) {
	offset = &Offset{}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "sound":
			offset.Sound = attr.Value == "yes"
		default:
			return offset, &UnknownAttribute{element, attr}
		}
	}

	offset.Divisions, err = ReadFloat32(r, element)
	return offset, err
}

func directionType(r xml.TokenReader, element xml.StartElement) (tp DirectionType, err error) {
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "words":
				words, err := ReadString(r, el)
				if err != nil {
					return err
				}
				tp.Words = append(tp.Words, words)
			case "metronome":
				if tp.Metronome != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.Metronome, err = metronome(r, el)
			case "dynamics":
				dynamic, err := dynamic(r, el)
				if err != nil {
					return err
				}
				tp.Dynamics = append(tp.Dynamics, dynamic)
			case "wedge":
				if tp.Wedge != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.Wedge, err = wedge(r, el)
			case "other-direction":
				if tp.OtherDirection != "" {
					return &FieldAlreadySet{element, el}
				}
				tp.OtherDirection, err = ReadString(r, el)
			case "octave-shift":
				if tp.OctaveShift != nil {
					return &FieldAlreadySet{element, el}
				}
				tp.OctaveShift, err = octaveShift(r, el)
			case "segno":
				if tp.Segno {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				tp.Segno = true
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return tp, err
}

func octaveShift(r xml.TokenReader, element xml.StartElement) (shift *OctaveShift, err error) {
	shift = &OctaveShift{Size: 8}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "type":
				shift.Type = attr.Value
			case "number":
				shift.Number, err = strconv.Atoi(attr.Value)
			case "size":
				shift.Size, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return shift, err
}

func wedge(r xml.TokenReader, element xml.StartElement) (wedge *Wedge, err error) {
	wedge = &Wedge{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			switch attr.Name.Local {
			case "number":
				wedge.Number, err = strconv.Atoi(attr.Value)
			case "type":
				wedge.Type = attr.Value
			default:
				return &UnknownAttribute{element, attr}
			}
			return err
		},
		func(el xml.StartElement) error {
			return &UnknownElement{element, el}
		})
	return wedge, err
}

func dynamic(r xml.TokenReader, element xml.StartElement) (dynamic *Dynamic, err error) {
	dynamic = &Dynamic{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			if ignoreLayoutAttribute(attr) {
				return nil
			}
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "p", "pp", "ppp", "pppp", "ppppp", "pppppp",
				"f", "ff", "fff", "ffff", "fffff", "ffffff",
				"mp", "mf", "sf", "sfp", "sfpp",
				"fp", "rf", "rfz", "sfz", "sffz", "fz",
				"n", "pf", "sfzp":
				err = ReadUntilClose(r, el)
				dynamic.Values = append(dynamic.Values, el.Name.Local)
			case "other-dynamics":
				val, err := ReadString(r, el)
				if err != nil {
					return err
				}
				dynamic.Values = append(dynamic.Values, val)
			}
			return err
		})
	return dynamic, err
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
				if metronome.BeatUnit != "" {
					return &FieldAlreadySet{element, el}
				}
				metronome.BeatUnit, err = ReadString(r, el)
			case "beat-unit-dot":
				if metronome.BeatUnitDot {
					return &FieldAlreadySet{element, el}
				}
				err = ReadUntilClose(r, el)
				metronome.BeatUnitDot = true
			case "per-minute":
				if metronome.PerMinute != 0 {
					return &FieldAlreadySet{element, el}
				}
				metronome.PerMinute, err = ReadInt(r, el)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	return metronome, err
}

func measureAttributes(r xml.TokenReader, element xml.StartElement) (attr *MeasureAttributes, err error) {
	def := NewMeasureAttributes()
	a := NewMeasureAttributes()
	attr = &a
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "divisions":
				if attr.Divisions != 0 {
					return &FieldAlreadySet{element, el}
				}
				attr.Divisions, err = ReadFloat32(r, el)
			case "key":
				if attr.Key != nil {
					return &FieldAlreadySet{element, el}
				}
				attr.Key, err = key(r, el)
			case "time":
				if attr.Time != nil {
					return &FieldAlreadySet{element, el}
				}
				attr.Time, err = timeSignature(r, el)
			case "staves":
				if attr.Staves != def.Staves {
					return &FieldAlreadySet{element, el}
				}
				attr.Staves, err = ReadInt(r, el)
			case "clef":
				c, err := clef(r, el)
				if err != nil {
					return err
				}
				attr.Clefs = append(attr.Clefs, c)
			case "staff-details":
				details, err := staffDetails(r, el)
				if err != nil {
					return err
				}
				attr.StaffDetails = append(attr.StaffDetails, details)
			case "transpose":
				tr, err := transpose(r, el)
				if err != nil {
					return err
				}
				attr.Transposes = append(attr.Transposes, tr)
			case "measure-style":
				err = ReadUntilClose(r, el) // IGNORE styling
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
				if transpose.Diatonic != nil {
					return &FieldAlreadySet{element, el}
				}
				diatonic, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				transpose.Diatonic = &diatonic
			case "chromatic":
				if transpose.Chromatic != 0 {
					return &FieldAlreadySet{element, el}
				}
				transpose.Chromatic, err = ReadInt(r, el)
			case "octave-change":
				if transpose.OctaveChange != nil {
					return &FieldAlreadySet{element, el}
				}
				octave, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				transpose.OctaveChange = &octave
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
			switch el.Name.Local {
			case "staff-lines":
				if staff.Lines != nil {
					return &FieldAlreadySet{element, el}
				}
				lines, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				staff.Lines = &lines
			case "staff-tuning":
				tuning, err := tuning(r, el)
				if err != nil {
					return err
				}
				staff.Tuning = append(staff.Tuning, tuning)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})

	return staff, err
}

func tuning(r xml.TokenReader, element xml.StartElement) (tuning *StaffTuning, err error) {
	tuning = &StaffTuning{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			switch attr.Name.Local {
			case "line":
				tuning.Line, err = strconv.Atoi(attr.Value)
			default:
				return &UnknownAttribute{element, attr}
			}
			return nil
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tuning-step":
				if tuning.step != "" {
					return &FieldAlreadySet{element, el}
				}
				tuning.step, err = ReadString(r, el)
			case "tuning-octave":
				if tuning.octave != 0 {
					return &FieldAlreadySet{element, el}
				}
				tuning.octave, err = ReadInt(r, el)
			case "tuning-alter":
				if tuning.alter != 0 {
					return &FieldAlreadySet{element, el}
				}
				tuning.alter, err = ReadFloat32(r, el)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return tuning, err
}

func clef(r xml.TokenReader, element xml.StartElement) (clef *Clef, err error) {
	clef = &Clef{Number: 1}
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
				if clef.Sign != "" {
					return &FieldAlreadySet{element, el}
				}
				clef.Sign, err = ReadString(r, el)
			case "line":
				if clef.Line != 0 {
					return &FieldAlreadySet{element, el}
				}
				clef.Line, err = ReadInt(r, el)
			case "clef-octave-change":
				if clef.OctaveChange != 0 {
					return &FieldAlreadySet{element, el}
				}
				clef.OctaveChange, err = ReadInt(r, el)
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
				if time.Beats != 0 {
					return &FieldAlreadySet{element, el}
				}
				time.Beats, err = ReadInt(r, el)
			case "beat-type":
				if time.BeatType != "" {
					return &FieldAlreadySet{element, el}
				}
				time.BeatType, err = ReadString(r, el)
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
				if key.Fifths != 0 {
					return &FieldAlreadySet{element, el}
				}
				i, err := ReadInt(r, el)
				if err != nil {
					return err
				}
				key.Fifths = Fifths(i)
			case "mode":
				if key.Mode != "" {
					return &FieldAlreadySet{element, el}
				}
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
			var item PartListItem
			switch el.Name.Local {
			case "part-group":
				item.PartGroup, err = partGroup(r, el)
			case "score-part":
				item.ScorePart, err = scorePart(r, el)
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
				part.NameDisplay, err = ReadNameDisplay(r, el)
			case "part-abbreviation":
				part.Abbreviation, err = ReadString(r, el)
			case "part-abbreviation-display":
				part.AbbreviationDisplay, err = ReadNameDisplay(r, el)
			case "score-instrument":
				instr, err := instrument(r, el)
				if err != nil {
					return err
				}
				part.Instruments = append(part.Instruments, instr)
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return part, err
}

func ReadNameDisplay(r xml.TokenReader, element xml.StartElement) (name *DisplayName, err error) {
	name = &DisplayName{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "display-text":
				text, err := ReadString(r, el)
				if err != nil {
					return err
				}
				name.Items = append(name.Items, DisplayNameItem{DisplayText: text})
			case "accidental-text":
				text, err := ReadString(r, el)
				if err != nil {
					return err
				}
				name.Items = append(name.Items, DisplayNameItem{AccidentalText: text})
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	if len(name.Items) == 0 {
		return nil, err
	}
	return name, err
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
			case "ensemble":
				val, err := ReadString(r, el)
				if err != nil {
					return err
				}
				if val == "" {
					return nil
				}
				ens, err := strconv.Atoi(val)
				if err != nil {
					return err
				}
				instr.Ensemble = &ens
				return nil
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
	group = &PartGroup{Number: 1}
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
				creator, err := typedText(r, el)
				if err != nil {
					return err
				}
				id.Creators = append(id.Creators, creator)
			case "rights":
				rights, err := typedText(r, el)
				if err != nil {
					return err
				}
				id.Rights = append(id.Rights, rights)
			case "encoding":
				if id.Encoding != nil {
					return &FieldAlreadySet{element, el}
				}
				id.Encoding, err = encoding(r, el)
			case "relation":
				relation, err := typedText(r, el)
				if err != nil {
					return err
				}
				id.Relation = append(id.Relation, relation)
			case "miscellaneous":
				err = ReadUntilClose(r, el) // IGNORE
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})

	if id.Encoding == nil && len(id.Creators) == 0 && len(id.Rights) == 0 && len(id.Relation) == 0 {
		return nil, err
	}
	return id, err
}

func typedText(r xml.TokenReader, element xml.StartElement) (text *TypedText, err error) {
	text = &TypedText{}

	token, err := r.Token()
	if err != nil {
		return text, err
	}

	for _, attr := range element.Attr {
		switch attr.Name.Local {
		case "type":
			text.Type = attr.Value
		default:
			return text, &UnknownAttribute{element, attr}
		}
	}

	switch el := token.(type) {
	case xml.CharData:
		text.Value = string(el)
	default:
		return text, &UnexpectedTokenError{element, token}
	}

	err = ReadUntilClose(r, element)
	return text, err
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
				if work.Title != "" {
					return &FieldAlreadySet{element, el}
				}
				work.Title, err = ReadString(r, el)
			case "work-number":
				if work.Number != "" {
					return &FieldAlreadySet{element, el}
				}
				work.Number, err = ReadString(r, el)
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
				if !encoding.Date.Equal(time.Time{}) {
					return &FieldAlreadySet{element, el}
				}
				encoding.Date, err = ReadTime(r, el)
			case "encoder", "software", "encoding-description", "supports":
				err = ReadUntilClose(r, el) // IGNORE from which software the xml was written
			default:
				err = &UnknownElement{element, el}
			}
			return err
		})
	return encoding, err
}

var layoutAttrs = []string{
	"print-object", "color",
	"default-x", "default-y", "valign", "width",
	"font-family", "font-style", "font-size", "font-weight",
	"placement",
}

func ignoreLayoutAttribute(attr xml.Attr) bool {
	return slices.Contains(layoutAttrs, attr.Name.Local)
}

package musicxml

import (
	"encoding/xml"
	"fmt"
	"strconv"
	"time"
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

func writePart(w *xml.Encoder, name string, part *Part) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "id"}, Value: part.Id},
		},
		func() error {
			for _, measure := range part.Measures {
				if err = writeMeasure(w, "measure", measure); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeMeasure(w *xml.Encoder, name string, measure *Measure) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "number"}, Value: measure.Number},
		},
		func() error {
			for _, element := range measure.Elements {
				if element.Attributes != nil {
					if err = writeMeasureAttributes(w, "attributes", element.Attributes); err != nil {
						return err
					}
				}
				if element.Backup != nil {
					if err = writeBackup(w, "backup", element.Backup); err != nil {
						return err
					}
				}
				if element.Direction != nil {
					if err = writeDirection(w, "direction", element.Direction); err != nil {
						return err
					}
				}
				if element.Forward != nil {
					if err = writeForward(w, "forward", element.Forward); err != nil {
						return err
					}
				}
				if element.Harmony != nil {
					if err = writeHarmony(w, "harmony", element.Harmony); err != nil {
						return err
					}
				}
				if element.Barline != nil {
					if err = writeBarline(w, "barline", element.Barline); err != nil {
						return err
					}
				}
				if element.Note != nil {
					if err = writeNote(w, "note", element.Note); err != nil {
						return nil
					}
				}
			}
			return nil
		})
}

func writeNote(w *xml.Encoder, name string, note *Note) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if note.Grace != nil {
				return writeGrace(w, "grace", note.Grace)
			}
			return nil
		},
		func() error {
			if note.Cue {
				return WriteObject(w, "cue", nil)
			}
			return nil
		},
		func() error {
			if note.IsChord {
				return WriteObject(w, "chord", nil)
			}
			return nil
		},
		func() error {
			if note.Pitch != nil {
				return writePitch(w, "pitch", note.Pitch)
			}
			return nil
		},
		func() error {
			if note.IsUnpitched {
				return WriteObject(w, "unpitched", nil)
			}
			return nil
		},
		func() error {
			if note.Rest != nil {
				return writeRest(w, "rest", note.Rest)
			}
			return nil
		},
		func() error {
			if note.Duration != 0 {
				return WriteString(w, "duration", strconv.Itoa(note.Duration), nil)
			}
			return nil
		},
		func() error {
			for _, tie := range note.Ties {
				if err = writeTie(w, "tie", tie); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, instrument := range note.Instruments {
				if err = writeInstrumentReference(w, "instrument", instrument); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if note.Voice != 0 {
				return WriteString(w, "voice", strconv.Itoa(note.Voice), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "type", note.Type, nil)
		},
		func() error {
			for i := 0; i < note.dotCount; i++ {
				if err = WriteObject(w, "dot", nil); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, accidental := range note.Accidentals {
				if err = writeAccidental(w, "accidental", accidental); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, mod := range note.TimeModifications {
				if err = writeTimeModification(w, "time-modification", mod); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if note.Stem == "" {
				return nil
			}
			return WriteString(w, "stem", note.Stem, nil)
		},
		func() error {
			if note.Head != nil {
				return writeNoteHead(w, "notehead", note.Head)
			}
			return nil
		},
		func() error {
			return WriteString(w, "staff", strconv.Itoa(note.Staff), nil)
		},
		func() error {
			for _, beam := range note.Beams {
				if err = writeBeam(w, "beam", beam); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, notation := range note.Notations {
				if err = writeNotation(w, "notations", notation); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, lyric := range note.Lyrics {
				if err = writeLyric(w, "lyric", lyric); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeGrace(w *xml.Encoder, name string, grace *Grace) (err error) {
	var attrs []xml.Attr
	if grace.Slash {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "slash"}, Value: "yes"})
	}
	return WriteObject(w, name, attrs)
}

func writeNoteHead(w *xml.Encoder, name string, head *NoteHead) (err error) {
	var attrs []xml.Attr
	if head.Filled {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "filled"}, Value: "yes"})
	}
	if head.Parentheses {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "parentheses"}, Value: "yes"})
	}
	return WriteString(w, name, head.Value, attrs)
}

func writeTimeModification(w *xml.Encoder, name string, time *TimeModification) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "actual-notes", strconv.Itoa(time.ActualNotes), nil)
		},
		func() error {
			return WriteString(w, "normal-notes", strconv.Itoa(time.NormalNotes), nil)
		},
		func() error {
			def := TimeModificationItem{}
			for _, item := range time.Items {
				if item.NormalType != def.NormalType {
					if err = WriteString(w, "normal-type", item.NormalType, nil); err != nil {
						return err
					}
				}
				if item.HasDot {
					if err = WriteObject(w, "normal-dot", nil); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

func writeAccidental(w *xml.Encoder, name string, accidental *Accidental) (err error) {
	return WriteString(w, name, accidental.Value, nil)
}

func writeNotation(w *xml.Encoder, name string, notation *Notation) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, tie := range notation.Ties {
				if err = writeTied(w, "tied", tie); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, slur := range notation.Slurs {
				if err = writeSlur(w, "slur", slur); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, tuplet := range notation.Tuplets {
				if err = writeTuplet(w, "tuplet", tuplet); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, fermata := range notation.Fermatas {
				if err = writeFermata(w, "fermata", fermata); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, dynamic := range notation.Dynamics {
				if err = writeDynamic(w, "dynamics", dynamic); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, articulation := range notation.Articulations {
				if err = writeArticulation(w, "articulations", articulation); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, slide := range notation.Slides {
				if err = writeSlide(w, "slide", slide); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, arpeggiate := range notation.Arpeggiate {
				if err = writeArpeggiate(w, "arpeggiate", arpeggiate); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, technical := range notation.Technical {
				if err = writeTechnical(w, "technical", technical); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, glissando := range notation.Glissandos {
				if err = writeGlissando(w, "glissando", glissando); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeGlissando(w *xml.Encoder, name string, glissando *Glissando) (err error) {
	def := Glissando{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: glissando.Type},
	}
	if glissando.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(glissando.Number)})
	}
	if glissando.LineType != def.LineType {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "lineType"}, Value: glissando.LineType})
	}
	return WriteObject(w, name, attrs)
}

func writeTechnical(w *xml.Encoder, name string, technical *Technical) (err error) {
	def := Technical{}
	return WriteObject(w, name, nil,
		func() error {
			if technical.Fret != def.Fret {
				if err = WriteString(w, "fret", strconv.Itoa(technical.Fret), nil); err != nil {
					return err
				}
			}
			if technical.String != def.String {
				if err = WriteString(w, "string", strconv.Itoa(technical.String), nil); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeArpeggiate(w *xml.Encoder, name string, _ *Arpeggiate) (err error) {
	return WriteObject(w, name, nil)
}

func writeSlide(w *xml.Encoder, name string, slide *Slide) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: slide.Type},
	})
}

func writeArticulation(w *xml.Encoder, name string, articulation *Articulations) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if articulation.Staccato {
				if err = WriteObject(w, "staccato", nil); err != nil {
					return err
				}
			}
			if articulation.BreathMark {
				if err = WriteObject(w, "breath-mark", nil); err != nil {
					return nil
				}
			}
			if articulation.Accent {
				if err = WriteObject(w, "accent", nil); err != nil {
					return nil
				}
			}
			if articulation.Tenuto {
				if err = WriteObject(w, "tenuto", nil); err != nil {
					return nil
				}
			}
			return nil
		})
}

func writeFermata(w *xml.Encoder, name string, fermata *Fermata) (err error) {
	var attrs []xml.Attr
	if fermata.IsInverted {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "type"}, Value: "inverted"})
	}

	return WriteString(w, name, fermata.Shape, attrs)
}

func writeTuplet(w *xml.Encoder, name string, tuplet *Tuplet) (err error) {
	def := Tuplet{}

	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: tuplet.Type},
	}

	if tuplet.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(tuplet.Number)})
	}
	if tuplet.Bracket != def.Bracket {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "bracket"}, Value: "yes"})
	}
	if tuplet.ShowNumber != def.ShowNumber {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "show-number"}, Value: tuplet.ShowNumber})
	}
	if tuplet.ShowType != def.ShowType {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "show-type"}, Value: tuplet.ShowType})
	}

	return WriteObject(w, name, attrs,
		func() error {
			for _, value := range tuplet.Values {
				if value.Actual != nil {
					if err = writeTupletPortion(w, "tuplet-actual", value.Actual); err != nil {
						return err
					}
				}
				if value.Normal != nil {
					if err = writeTupletPortion(w, "tuplet-normal", value.Actual); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

func writeTupletPortion(w *xml.Encoder, name string, tuplet *TupletPortion) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "tuplet-number", strconv.Itoa(tuplet.Number), nil)
		},
		func() error {
			return WriteString(w, "tuplet-type", tuplet.Type, nil)
		},
		func() error {
			for i := 0; i < tuplet.Number; i++ {
				if err = WriteObject(w, "tuplet-dot", nil); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeSlur(w *xml.Encoder, name string, slur *Slur) (err error) {
	def := Slur{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: slur.Type},
	}
	if slur.Orientation != def.Orientation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "orientation"}, Value: slur.Orientation})
	}
	if slur.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(slur.Number)})
	}
	return WriteObject(w, name, attrs)
}

func writeTied(w *xml.Encoder, name string, tied *Tied) (err error) {
	def := Tied{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: tied.Type},
	}
	if tied.Orientation != def.Orientation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "orientation"}, Value: tied.Orientation})
	}
	return WriteObject(w, name, attrs)
}

func writeTie(w *xml.Encoder, name string, tie *Tie) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "type"}, Value: tie.Type}})
}

func writeRest(w *xml.Encoder, name string, rest *Rest) (err error) {
	var attrs []xml.Attr
	if rest.Measure {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "measure"}, Value: "yes"})
	}
	return WriteObject(w, name, attrs)
}

func writeLyric(w *xml.Encoder, name string, lyric *Lyric) (err error) {
	def := Lyric{}
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "number"}, Value: lyric.Number}},
		func() error {
			if lyric.Syllabic != def.Syllabic {
				return WriteString(w, "syllabic", lyric.Syllabic, nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "text", lyric.Text, nil)
		},
		func() error {
			if lyric.Extend != nil {
				return writeExtend(w, "extend", lyric.Extend)
			}
			return nil
		})
}

func writeExtend(w *xml.Encoder, name string, extend *Extend) (err error) {
	var attrs []xml.Attr
	if extend.Type != "" {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "type"}, Value: extend.Type})
	}
	return WriteObject(w, name, attrs)
}

func writeBeam(w *xml.Encoder, name string, beam *Beam) (err error) {
	def := Beam{}
	var attrs []xml.Attr

	if beam.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(beam.Number)})
	}

	return WriteString(w, name, beam.Type, attrs)
}

func writeInstrumentReference(w *xml.Encoder, name string, ref string) error {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "id"}, Value: ref},
	})
}

func writePitch(w *xml.Encoder, name string, pitch *Pitch) (err error) {
	def := Pitch{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "step", string(pitch.Step), nil)
		},
		func() error {
			if pitch.Alter != def.Alter {
				return WriteString(w, "alter", fmt.Sprintf("%g", pitch.Alter), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "octave", strconv.Itoa(pitch.Octave), nil)
		})
}

func writeBarline(w *xml.Encoder, name string, barline *Barline) (err error) {
	def := Barline{}
	var attrs []xml.Attr
	if barline.Location != def.Location {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "location"}, Value: barline.Location})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if barline.Style != def.Style {
				return WriteString(w, "bar-style", barline.Style, nil)
			}
			return nil
		},
		func() error {
			if barline.Ending != nil {
				return writeEnding(w, "ending", barline.Ending)
			}
			return nil
		},
		func() error {
			if barline.Repeat != nil {
				return writeRepeat(w, "repeat", barline.Repeat)
			}
			return nil
		},
	)
}

func writeEnding(w *xml.Encoder, name string, ending *Ending) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "number"}, Value: ending.Number},
		{Name: xml.Name{Local: "type"}, Value: ending.Type},
	})
}

func writeRepeat(w *xml.Encoder, name string, repeat *Repeat) (err error) {
	return WriteObject(w, name, []xml.Attr{
		{Name: xml.Name{Local: "direction"}, Value: repeat.Direction},
	})
}

func writeHarmony(w *xml.Encoder, name string, harmony *Harmony) (err error) {
	def := Harmony{}
	return WriteObject(w, name, nil,
		func() error {
			if harmony.Root != nil {
				return writeHarmonyRoot(w, "root", harmony.Root)
			}
			return nil
		},
		func() error {
			if harmony.Kind != def.Kind {
				return WriteString(w, "kind", harmony.Kind, nil)
			}
			return nil
		},
		func() error {
			if harmony.Bass != nil {
				return writeBass(w, "bass", harmony.Bass)
			}
			return nil
		},
		func() error {
			for _, degree := range harmony.Degrees {
				if err = writeDegree(w, "degree", degree); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if harmony.Frame != nil {
				return writeFrame(w, "frame", harmony.Frame)
			}
			return nil
		},
		func() error {
			if harmony.Staff != def.Staff {
				return WriteString(w, "staff", strconv.Itoa(harmony.Staff), nil)
			}
			return nil
		})
}

func writeFrame(w *xml.Encoder, name string, frame *Frame) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "frame-strings", strconv.Itoa(frame.Strings), nil)
		},
		func() error {
			return WriteString(w, "frame-frets", strconv.Itoa(frame.Frets), nil)
		},
		func() error {
			if frame.FirstFret != nil {
				return writeFirstFret(w, "first-fret", frame.FirstFret)
			}
			return nil
		},
		func() error {
			for _, note := range frame.Notes {
				if err = writeFrameNote(w, "frame-note", note); err != nil {
					return err
				}
			}
			return nil
		})
}

func writeFrameNote(w *xml.Encoder, name string, note *FrameNote) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "string", strconv.Itoa(note.String), nil)
		},
		func() error {
			return WriteString(w, "fret", strconv.Itoa(note.Fret), nil)
		},
		func() error {
			if note.Fingering != nil {
				return writeFingering(w, "fingering", note.Fingering)
			}
			return nil
		},
		func() error {
			if note.Barre != nil {
				return writeBarre(w, "barre", note.Barre)
			}
			return nil
		})
}

func writeBarre(w *xml.Encoder, name string, barre *Barre) (err error) {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "type"}, Value: barre.Type}})
}

func writeFingering(w *xml.Encoder, name string, fingering *Fingering) (err error) {
	var attrs []xml.Attr
	if fingering.Substitution {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "substitution"}, Value: "yes"})
	}
	if fingering.Alternate {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "alternate"}, Value: "yes"})
	}
	return WriteString(w, name, fingering.Value, nil)
}

func writeFirstFret(w *xml.Encoder, name string, fret *FirstFret) (err error) {
	def := FirstFret{}
	var attrs []xml.Attr
	if fret.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: fret.Text})
	}
	if fret.Location != def.Location {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "location"}, Value: fret.Location})
	}

	return WriteString(w, name, strconv.Itoa(fret.Value), attrs)
}

func writeDegree(w *xml.Encoder, name string, degree *Degree) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return writeDegreeValue(w, "degree-value", degree.Value)
		},
		func() error {
			return writeDegreeAlter(w, "degree-alter", degree.Alter)
		},
		func() error {
			return writeDegreeType(w, "degree-type", degree.Type)
		})
}

func writeDegreeType(w *xml.Encoder, name string, tp *DegreeType) (err error) {
	def := DegreeType{}
	var attrs []xml.Attr
	if tp.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: tp.Text})
	}
	return WriteString(w, name, tp.Value, attrs)
}

func writeDegreeAlter(w *xml.Encoder, name string, alter *DegreeAlter) (err error) {
	var attrs []xml.Attr
	if alter.PlusMinus {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "plus-minus"}, Value: "yes"})
	}
	return WriteString(w, name, fmt.Sprintf("%g", alter.Value), attrs)
}

func writeDegreeValue(w *xml.Encoder, name string, value *DegreeValue) (err error) {
	def := DegreeValue{}
	var attrs []xml.Attr
	if value.Symbol != def.Symbol {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "symbol"}, Value: value.Symbol})
	}
	if value.Text != def.Text {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "text"}, Value: value.Text})
	}
	return WriteString(w, name, strconv.Itoa(value.Value), attrs)
}

func writeBass(w *xml.Encoder, name string, bass *Bass) (err error) {
	def := Bass{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "bass-step", bass.Step, nil)
		},
		func() error {
			if bass.Alter != def.Alter {
				return WriteString(w, "bass-alter", bass.Alter, nil)
			}
			return nil
		})
}

func writeHarmonyRoot(w *xml.Encoder, name string, root *HarmonyRoot) (err error) {
	def := HarmonyRoot{}
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "root-step", string(root.Step), nil)
		},
		func() error {
			if root.Alter != def.Alter {
				return WriteString(w, "root-alter", fmt.Sprintf("%g", root.Alter), nil)
			}
			return nil
		})
}

func writeForward(w *xml.Encoder, name string, forward *Forward) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "duration", fmt.Sprintf("%g", forward.Duration), nil)
		})
}

func writeDirection(w *xml.Encoder, name string, direction *Direction) (err error) {
	def := Direction{}
	return WriteObject(w, name, nil,
		func() error {
			for _, direction := range direction.DirectionTypes {
				if err = writeDirectionType(w, "direction-type", direction); err != nil {
					return err
				}
			}
			return err
		},
		func() error {
			if direction.Offset != nil {
				return writeOffset(w, "offset", direction.Offset)
			}
			return nil
		},
		func() error {
			if direction.Voice != def.Voice {
				return WriteString(w, "voice", direction.Voice, nil)
			}
			return nil
		},
		func() error {
			if direction.Staff != def.Staff {
				return WriteString(w, "staff", strconv.Itoa(direction.Staff), nil)
			}
			return nil
		},
		func() error {
			if direction.Sound != nil {
				return writeSound(w, "sound", direction.Sound)
			}
			return nil
		},
	)
}

func writeSound(w *xml.Encoder, name string, sound *Sound) (err error) {
	def := Sound{}
	var attrs []xml.Attr
	if sound.ToCoda != def.ToCoda {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "tocoda"}, Value: sound.ToCoda})
	}
	if sound.TimeOnly != def.TimeOnly {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "time-only"}, Value: sound.TimeOnly})
	}
	if sound.Tempo != def.Tempo {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "tempo"}, Value: fmt.Sprintf("%g", sound.Tempo)})
	}
	if sound.Dynamics != def.Dynamics {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dynamics"}, Value: fmt.Sprintf("%g", sound.Dynamics)})
	}
	if sound.DaCapo {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dacapo"}, Value: "yes"})
	}
	if sound.Segno {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "segno"}, Value: "yes"})
	}
	if sound.DalSegno {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "dalsegno"}, Value: "yes"})
	}
	if sound.Coda != def.Coda {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "coda"}, Value: sound.Coda})
	}
	if sound.Divisions != def.Divisions {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "divisions"}, Value: fmt.Sprintf("%g", sound.Divisions)})
	}
	if sound.ForwardRepeat {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "forward-repeat"}, Value: "yes"})
	}
	if sound.Fine != def.Fine {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "fine"}, Value: sound.Fine})
	}
	if sound.Pizzicato {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "pizzicato"}, Value: "yes"})
	}
	if sound.Pan != def.Pan {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "pan"}, Value: fmt.Sprintf("%g", sound.Pan)})
	}
	if sound.Elevation != def.Elevation {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "elevation"}, Value: fmt.Sprintf("%g", sound.Elevation)})
	}
	if sound.DamperPedal != def.DamperPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "damper-pedal"}, Value: sound.DamperPedal})
	}
	if sound.SoftPedal != def.SoftPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "soft-pedal"}, Value: sound.SoftPedal})
	}
	if sound.SostenutoPedal != def.SostenutoPedal {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "sostenuto-pedal"}, Value: sound.SostenutoPedal})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if sound.Offset != nil {
				return writeOffset(w, "offset", sound.Offset)
			}
			return nil
		})
}

func writeOffset(w *xml.Encoder, name string, offset *Offset) (err error) {
	var attrs []xml.Attr
	if offset.Sound {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "sound"}, Value: "yes"})
	}
	return WriteString(w, name, fmt.Sprintf("%g", offset.Divisions), attrs)
}

func writeDirectionType(w *xml.Encoder, name string, direction DirectionType) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			if direction.Segno {
				return WriteObject(w, "segno", nil)
			}
			return nil
		},
		func() error {
			for _, words := range direction.Words {
				return WriteString(w, "words", words, nil)
			}
			return nil
		},
		func() error {
			if direction.Wedge != nil {
				return writeWedge(w, "wedge", direction.Wedge)
			}
			return nil
		},
		func() error {
			for _, dynamic := range direction.Dynamics {
				if err = writeDynamic(w, "dynamics", dynamic); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			if direction.Metronome != nil {
				return writeMetronome(w, "metronome", direction.Metronome)
			}
			return nil
		},
		func() error {
			if direction.OctaveShift != nil {
				return writeOctaveShift(w, "octave-shift", direction.OctaveShift)
			}
			return nil
		},
		func() error {
			if direction.OtherDirection != "" {
				return WriteString(w, "other-direction", direction.OtherDirection, nil)
			}
			return nil
		},
	)
}

func writeOctaveShift(w *xml.Encoder, name string, octaveShift *OctaveShift) (err error) {
	def := OctaveShift{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: octaveShift.Type},
	}
	if octaveShift.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(octaveShift.Number)})
	}
	if octaveShift.Size != def.Size {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "size"}, Value: octaveShift.Type})
	}
	return WriteObject(w, name, attrs)
}

func writeMetronome(w *xml.Encoder, name string, metronome *Metronome) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "beat-unit", metronome.BeatUnit, nil)
		},
		func() error {
			if metronome.BeatUnitDot {
				return WriteObject(w, "beat-unit-dot", nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "per-minute", strconv.Itoa(metronome.PerMinute), nil)
		})
}

func writeDynamic(w *xml.Encoder, name string, dynamic *Dynamic) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, dynamic := range dynamic.Values {
				if err = WriteObject(w, dynamic, nil); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

func writeWedge(w *xml.Encoder, name string, wedge *Wedge) (err error) {
	def := Wedge{}
	attrs := []xml.Attr{
		{Name: xml.Name{Local: "type"}, Value: wedge.Type},
	}
	if wedge.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(wedge.Number)})
	}
	return WriteObject(w, name, attrs)
}

func writeBackup(w *xml.Encoder, name string, backup *Backup) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "duration", fmt.Sprintf("%g", backup.Duration), nil)
		})
}

func writeMeasureAttributes(w *xml.Encoder, name string, attributes *MeasureAttributes) (err error) {
	def := MeasureAttributes{}
	return WriteObject(w, name,
		nil,
		func() error {
			if attributes.Divisions != def.Divisions {
				return WriteString(w, "divisions", fmt.Sprintf("%g", attributes.Divisions), nil)
			}
			return nil
		},
		func() error {
			if attributes.Key != nil {
				return writeKey(w, "key", attributes.Key)
			}
			return nil
		},
		func() error {
			if attributes.Time != nil {
				return writeTimeSignature(w, "time", attributes.Time)
			}
			return nil
		},
		func() error {
			if attributes.Staves != def.Staves {
				return WriteString(w, "staves", strconv.Itoa(attributes.Staves), nil)
			}
			return nil
		},
		func() error {
			for _, clef := range attributes.Clefs {
				if err := writeClef(w, "clef", clef); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, details := range attributes.StaffDetails {
				if err := writeStaffDetails(w, "staff-details", details); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, transpose := range attributes.Transposes {
				if err := writeTranspose(w, "transpose", transpose); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

func writeTranspose(w *xml.Encoder, name string, transpose *Transpose) (err error) {
	return WriteObject(w, name,
		nil,
		func() error {
			if transpose.Diatonic != nil {
				return WriteString(w, "diatonic", strconv.Itoa(*transpose.Diatonic), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "chromatic", strconv.Itoa(transpose.Chromatic), nil)
		},
		func() error {
			if transpose.OctaveChange != nil {
				return WriteString(w, "octave-change", strconv.Itoa(*transpose.OctaveChange), nil)
			}
			return nil
		},
	)
}

func writeStaffDetails(w *xml.Encoder, name string, details *StaffDetails) (err error) {
	def := StaffDetails{}
	var attrs []xml.Attr
	if details.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(details.Number)})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if details.Lines != nil {
				return WriteString(w, "staff-lines", strconv.Itoa(*details.Lines), nil)
			}
			return nil
		},
		func() error {
			for _, tuning := range details.Tuning {
				if err = writeTuning(w, "staff-tuning", tuning); err != nil {
					return err
				}
			}
			return nil
		},
	)
}

func writeTuning(w *xml.Encoder, name string, tuning *StaffTuning) (err error) {
	def := StaffTuning{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "line"}, Value: strconv.Itoa(tuning.Line)},
		},
		func() error {
			return WriteString(w, "tuning-step", tuning.step, nil)
		},
		func() error {
			if tuning.alter != def.alter {
				return WriteString(w, "tuning-alter", fmt.Sprintf("%g", tuning.alter), nil)
			}
			return nil
		},
		func() error {
			return WriteString(w, "tuning-octave", strconv.Itoa(tuning.octave), nil)
		})
}

func writeClef(w *xml.Encoder, name string, clef *Clef) (err error) {
	def := Clef{}
	var attrs []xml.Attr
	if clef.Number != def.Number {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(clef.Number)})
	}
	return WriteObject(w, name, attrs,
		func() error {
			if clef.Sign != def.Sign {
				return WriteString(w, "sign", clef.Sign, nil)
			}
			return nil
		},
		func() error {
			if clef.Line != def.Line {
				return WriteString(w, "line", strconv.Itoa(clef.Line), nil)
			}
			return nil
		},
		func() error {
			if clef.OctaveChange != def.OctaveChange {
				return WriteString(w, "clef-octave-change", strconv.Itoa(clef.OctaveChange), nil)
			}
			return nil
		})
}

func writeTimeSignature(w *xml.Encoder, name string, time *TimeSignature) (err error) {
	def := TimeSignature{}
	var attrs []xml.Attr
	if time.Symbol != def.Symbol {
		attrs = append(attrs, xml.Attr{Name: xml.Name{Local: "symbol"}, Value: time.Symbol})
	}
	return WriteObject(w, name, attrs,
		func() error {
			return WriteString(w, "beats", strconv.Itoa(time.Beats), nil)
		},
		func() error {
			return WriteString(w, "beat-type", time.BeatType, nil)
		},
	)
}

func writeKey(w *xml.Encoder, name string, key *Key) (err error) {
	def := Key{}
	return WriteObject(w, name,
		nil,
		func() error {
			return WriteString(w, "fifths", strconv.Itoa(int(key.Fifths)), nil)
		},
		func() error {
			if key.Mode != def.Mode {
				return WriteString(w, "mode", key.Mode, nil)
			}
			return nil
		},
	)
}

func writePartList(w *xml.Encoder, name string, partList []PartListItem) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, item := range partList {
				if item.PartGroup != nil {
					if err = writePartGroup(w, "part-group", item.PartGroup); err != nil {
						return err
					}
				}
				if item.ScorePart != nil {
					if err = writeScorePart(w, "score-part", item.ScorePart); err != nil {
						return err
					}
				}
			}
			return nil
		})
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

func writeDisplayName(w *xml.Encoder, name string, display *DisplayName) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			def := DisplayNameItem{}
			for _, item := range display.Items {
				if item.DisplayText != def.DisplayText {
					if err = WriteString(w, "display-text", item.DisplayText, nil); err != nil {
						return err
					}
				}
				if item.AccidentalText != def.AccidentalText {
					if err = WriteString(w, "accidental-text", item.AccidentalText, nil); err != nil {
						return err
					}
				}
			}
			return nil
		})
}

func writeInstrument(w *xml.Encoder, name string, instr *Instrument) (err error) {
	def := Instrument{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "id"}, Value: instr.Id},
		},
		func() error {
			return WriteString(w, "instrument-name", instr.Name, nil)
		},
		func() error {
			if instr.Sound != def.Sound {
				return WriteString(w, "instrument-sound", instr.Sound, nil)
			}
			return nil
		},
		func() error {
			if instr.IsSolo {
				return WriteObject(w, "solo", nil)
			}
			return nil
		},
		func() error {
			if instr.Ensemble != nil {
				return WriteString(w, "ensemble", strconv.Itoa(*instr.Ensemble), nil)
			}
			return nil
		},
	)
}

func writePartGroup(w *xml.Encoder, name string, group *PartGroup) (err error) {
	def := PartGroup{}
	return WriteObject(w, name,
		[]xml.Attr{
			{Name: xml.Name{Local: "type"}, Value: group.Type},
			{Name: xml.Name{Local: "number"}, Value: strconv.Itoa(group.Number)},
		},
		func() error {
			if group.Symbol != def.Symbol {
				return WriteString(w, "group-symbol", group.Symbol, nil)
			}
			return nil
		})
}

func writeDefaults(w *xml.Encoder, name string, defaults *Defaults) (err error) {
	def := Defaults{}
	return WriteObject(w, name, nil,
		func() error {
			if defaults.LyricLanguage != def.LyricLanguage {
				return writeLanguage(w, "lyric-language", defaults.LyricLanguage)
			}
			return nil
		})
}

func writeLanguage(w *xml.Encoder, name string, language string) error {
	return WriteObject(w, name,
		[]xml.Attr{{Name: xml.Name{Local: "xml:lang"}, Value: language}},
	)
}

func writeIdentification(w *xml.Encoder, name string, identification *Identification) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, creator := range identification.Creators {
				if err = writeTypedText(w, "creator", creator); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, rights := range identification.Rights {
				if err = writeTypedText(w, "rights", rights); err != nil {
					return nil
				}
			}
			return nil
		},
		func() error {
			if identification.Encoding != nil {
				return writeEncoding(w, "encoding")
			}
			return nil
		},
		func() error {
			for _, relation := range identification.Relation {
				if err = writeTypedText(w, "relation", relation); err != nil {
					return nil
				}
			}
			return nil
		})
}

func writeEncoding(w *xml.Encoder, name string) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			return WriteString(w, "encoding-date", time.Now().UTC().Format("2006-01-02"), nil)
		})
}

func writeTypedText(w *xml.Encoder, name string, text *TypedText) (err error) {
	return WriteString(w, name,
		text.Value,
		[]xml.Attr{{Name: xml.Name{Local: "type"}, Value: text.Type}},
	)
}

func writeWork(w *xml.Encoder, name string, work *Work) (err error) {
	def := Work{}
	return WriteObject(w, name, nil,
		func() error {
			if work.Title == def.Title {
				return nil
			}
			return WriteString(w, "work-title", work.Title, nil)
		},
		func() error {
			if work.Number == def.Number {
				return nil
			}
			return WriteString(w, "work-number", work.Number, nil)
		})
}

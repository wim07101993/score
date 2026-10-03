package musicxml

import (
	"encoding/xml"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const exampleDataDir = "../../test/example_data"

func parseExample(t *testing.T, name string) *ScorePartwise {
	t.Helper()

	f, err := os.Open(filepath.Join(exampleDataDir, name))
	if err != nil {
		t.Fatalf("failed to open example file %s: %v", name, err)
	}
	t.Cleanup(func() { _ = f.Close() })

	score, err := DeserializeMusicXml(xml.NewDecoder(f))
	if err != nil {
		t.Fatalf("failed to deserialize %s: %v", name, err)
	}
	if score == nil {
		t.Fatalf("deserializing %s returned a nil score without an error", name)
	}
	return score
}

func parseString(t *testing.T, doc string) (*ScorePartwise, error) {
	t.Helper()
	return DeserializeMusicXml(xml.NewDecoder(strings.NewReader(doc)))
}

// creatorsOfType collects the creator values of a single type ("composer",
// "lyricist", ...) in document order.
func creatorsOfType(score *ScorePartwise, creatorType string) []string {
	if score.Identification == nil {
		return nil
	}
	var values []string
	for _, creator := range score.Identification.Creators {
		if creator.Type == creatorType {
			values = append(values, creator.Value)
		}
	}
	return values
}

// instrumentSounds collects every non-empty instrument-sound in the part-list,
// which is what the score database persists as a score's instruments.
func instrumentSounds(score *ScorePartwise) []string {
	var sounds []string
	for _, item := range score.PartList {
		if item.ScorePart == nil {
			continue
		}
		for _, instrument := range item.ScorePart.Instruments {
			if instrument.Sound == "" {
				continue
			}
			sounds = append(sounds, instrument.Sound)
		}
	}
	return sounds
}

func assertStrings(t *testing.T, field string, got, want []string) {
	t.Helper()
	if len(got) != len(want) {
		t.Errorf("%s = %v, want %v", field, got, want)
		return
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("%s = %v, want %v", field, got, want)
			return
		}
	}
}

func TestDeserializeWorkScopedExample(t *testing.T) {
	score := parseExample(t, "BeetAnGeSample.musicxml")

	if score.Work == nil {
		t.Fatal("Work is nil, want the <work> element to be parsed")
	}
	if got, want := score.Work.Title, "An die ferne Geliebte (Page 1)"; got != want {
		t.Errorf("Work.Title = %q, want %q", got, want)
	}
	if got, want := score.Work.Number, "Op. 98"; got != want {
		t.Errorf("Work.Number = %q, want %q", got, want)
	}
	if got := score.MovementTitle; got != "" {
		t.Errorf("MovementTitle = %q, want empty (the document has no <movement-title>)", got)
	}
	if got := score.MovementNumber; got != "" {
		t.Errorf("MovementNumber = %q, want empty (the document has no <movement-number>)", got)
	}

	assertStrings(t, "composers", creatorsOfType(score, "composer"), []string{"Ludwig van Beethoven"})
	assertStrings(t, "lyricists", creatorsOfType(score, "lyricist"), []string{"Aloys Jeitteles"})

	if score.Defaults == nil {
		t.Fatal("Defaults is nil, want the <defaults> element to be parsed")
	}
	if got, want := score.Defaults.LyricLanguage, "de"; got != want {
		t.Errorf("Defaults.LyricLanguage = %q, want %q", got, want)
	}

	assertStrings(t, "instrument sounds", instrumentSounds(score), []string{"voice.vocals", "keyboard.piano"})
}

func TestDeserializeMovementScopedExample(t *testing.T) {
	score := parseExample(t, "BrahWiMeSample.musicxml")

	if got, want := score.MovementTitle, "Wie Melodien zieht es mir (Page 1)"; got != want {
		t.Errorf("MovementTitle = %q, want %q", got, want)
	}

	// This document carries no <work> element at all. Every consumer of a
	// parsed score has to cope with that, so the parser is expected to leave
	// Work nil rather than invent an empty one.
	if score.Work != nil {
		t.Errorf("Work = %+v, want nil for a document without a <work> element", *score.Work)
	}

	assertStrings(t, "composers", creatorsOfType(score, "composer"), []string{"Johannes Brahms"})
	assertStrings(t, "lyricists", creatorsOfType(score, "lyricist"), []string{"Klaus Groth"})
	assertStrings(t, "instrument sounds", instrumentSounds(score), []string{"voice.vocals", "keyboard.piano"})
}

func TestDeserializeSupportedVersions(t *testing.T) {
	tests := []struct {
		version string
		wantErr bool
	}{
		{version: "3.0"},
		{version: "3.1"},
		{version: "4.0"},
		{version: "2.0", wantErr: true},
		{version: "5.0", wantErr: true},
		{version: "", wantErr: true},
	}

	for _, tt := range tests {
		t.Run("version="+tt.version, func(t *testing.T) {
			doc := `<score-partwise version="` + tt.version + `"><work><work-title>T</work-title></work></score-partwise>`
			_, err := parseString(t, doc)
			if tt.wantErr && err == nil {
				t.Errorf("parsing version %q succeeded, want an error", tt.version)
			}
			if !tt.wantErr && err != nil {
				t.Errorf("parsing version %q failed: %v", tt.version, err)
			}
		})
	}
}

// TestDeserializeAcceptsAnyIndentation checks that insignificant whitespace
// between elements is ignored whichever character it is made of. Which
// characters an editor indents with says nothing about whether a document is
// valid MusicXML.
func TestDeserializeAcceptsAnyIndentation(t *testing.T) {
	tests := []struct {
		name   string
		indent string
	}{
		{name: "two spaces", indent: "  "},
		{name: "four spaces", indent: "    "},
		{name: "tab", indent: "\t"},
		{name: "carriage return and tab", indent: "\r\t"},
		{name: "no indentation", indent: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			doc := "<score-partwise version=\"4.0\">\n" +
				tt.indent + "<work>\n" +
				tt.indent + tt.indent + "<work-title>Indented</work-title>\n" +
				tt.indent + "</work>\n" +
				"</score-partwise>"

			score, err := parseString(t, doc)
			if err != nil {
				t.Fatalf("failed to parse a document indented with %q: %v", tt.indent, err)
			}
			if score.Work == nil {
				t.Fatal("Work is nil, want the <work> element to be parsed")
			}
			if got, want := score.Work.Title, "Indented"; got != want {
				t.Errorf("Work.Title = %q, want %q", got, want)
			}
		})
	}
}

// exportedScore is a small score the way an exporter writes one, with the
// given markup put in at each of the places the tests below need something
// that is not in the baseline. It is a function rather than a template so that
// each case says only what is different about it.
type exportedScore struct {
	rootAttributes string
	work           string
	identification string
	defaults       string
	partList       string
	scorePart      string
	instrument     string
}

func (e exportedScore) String() string {
	work := e.work
	if work == "" {
		work = `<work-title>Sonata</work-title>`
	}
	identification := e.identification
	if identification == "" {
		identification = `<creator type="composer">Ludwig van Beethoven</creator>`
	}
	return `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0"` + e.rootAttributes + `>
  <work>` + work + `</work>
  <identification>` + identification + `</identification>
  ` + e.defaults + `
  <part-list>
    ` + e.partList + `
    <score-part id="P1">
      <part-name>Violin</part-name>
      ` + e.scorePart + `
      <score-instrument id="P1-I1">
        <instrument-name>Violin</instrument-name>
        ` + e.instrument + `
        <instrument-sound>strings.violin</instrument-sound>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions></attributes>
      <note><rest measure="yes"/><duration>4</duration></note>
    </measure>
  </part>
</score-partwise>`
}

// TestDeserializeSkipsWhatItDoesNotKnow is about documents that are valid
// MusicXML and carry something this parser has no use for. Every one of them
// is what a real exporter writes — MuseScore, Finale, Sibelius — and every one
// of them used to be refused as invalid. What is read out of them has to be the
// same as if the extra had not been there at all.
func TestDeserializeSkipsWhatItDoesNotKnow(t *testing.T) {
	tests := map[string]exportedScore{
		"concert pitch in the defaults": {defaults: `<defaults><concert-score/></defaults>`},
		"a named staff group": {partList: `<part-group type="start" number="1">
			<group-name>Strings</group-name>
			<group-name-display><display-text>Strings</display-text></group-name-display>
			<group-abbreviation>Str.</group-abbreviation>
			<group-symbol>bracket</group-symbol>
			<group-time/>
		</part-group>`},
		"a part in a group of parts":    {scorePart: `<group>score</group>`},
		"a player of a part":            {scorePart: `<player id="P1-M1"><player-name>Player 1</player-name></player>`},
		"an instrument abbreviation":    {instrument: `<instrument-abbreviation>Vln.</instrument-abbreviation>`},
		"a link to the part's own file": {rootAttributes: ` xmlns:xlink="http://www.w3.org/1999/xlink"`, scorePart: `<part-link xlink:href="parts/violin.musicxml"/>`},
		"a namespace on the root":       {rootAttributes: ` xmlns:xlink="http://www.w3.org/1999/xlink"`},
		"a schema location on the root": {rootAttributes: ` xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.musicxml.org/xsd/musicxml.xsd"`},
		"an opus":                       {work: `<work-title>Sonata</work-title><opus xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="opus.musicxml"/>`},
		"an empty rights statement":     {identification: `<creator type="composer">Ludwig van Beethoven</creator><rights></rights>`},
		"a numbered lyric language":     {defaults: `<defaults><lyric-language number="1" xml:lang="de"/></defaults>`},
		"a named lyric language":        {defaults: `<defaults><lyric-language name="verse" xml:lang="de"/></defaults>`},
		"an element nobody has heard of, holding one of the same name": {
			defaults: `<defaults><something-new><something-new/><lyric-language xml:lang="fr"/></something-new></defaults>`},
	}

	for name, document := range tests {
		t.Run(name, func(t *testing.T) {
			score, err := parseString(t, document.String())
			if err != nil {
				t.Fatalf("failed to parse a valid document with %s: %v", name, err)
			}
			if score.Work == nil || score.Work.Title != "Sonata" {
				t.Errorf("Work = %+v, want the title Sonata", score.Work)
			}
			assertStrings(t, "composers", creatorsOfType(score, "composer"), []string{"Ludwig van Beethoven"})
			assertStrings(t, "instrument sounds", instrumentSounds(score), []string{"strings.violin"})
		})
	}

	t.Run("what is skipped leaves what is read alone", func(t *testing.T) {
		score, err := parseString(t, exportedScore{
			defaults: `<defaults><concert-score/><lyric-language number="1" xml:lang="de"/></defaults>`,
			partList: `<part-group type="start" number="2"><group-name>Strings</group-name><group-barline>yes</group-barline></part-group>`,
		}.String())
		if err != nil {
			t.Fatalf("failed to parse: %v", err)
		}
		if score.Defaults == nil || score.Defaults.LyricLanguage != "de" {
			t.Errorf("Defaults = %+v, want the lyric language de", score.Defaults)
		}
		if len(score.PartList) != 2 || score.PartList[0].PartGroup == nil {
			t.Fatalf("PartList = %+v, want the group and then the part", score.PartList)
		}
		if group := score.PartList[0].PartGroup; group.Number != 2 || !group.GroupBarline {
			t.Errorf("PartGroup = %+v, want number 2 with a group barline", *group)
		}
	})
}

// TestDeserializeReadsAnEmptyCreator covers an exporter that knows there is a
// composer but not who: the element is there with nothing in it, which the
// schema allows.
func TestDeserializeReadsAnEmptyCreator(t *testing.T) {
	score, err := parseString(t, exportedScore{identification: `<creator type="composer"/>`}.String())
	if err != nil {
		t.Fatalf("failed to parse a document with an empty creator: %v", err)
	}
	assertStrings(t, "composers", creatorsOfType(score, "composer"), []string{""})
}

// TestDeserializeReadsTheWholeText is about text that is not written down as
// one piece. A CDATA section is text like any other, and a comment in the
// middle of a title is not part of it — but neither of them ends it.
func TestDeserializeReadsTheWholeText(t *testing.T) {
	tests := map[string]struct {
		title string
		want  string
	}{
		"a CDATA section in the middle": {title: `Romeo <![CDATA[&]]> Juliet`, want: "Romeo & Juliet"},
		"all of it a CDATA section":     {title: `<![CDATA[Romeo & Juliet]]>`, want: "Romeo & Juliet"},
		"a comment in the middle":       {title: `Romeo<!-- and --> and Juliet`, want: "Romeo and Juliet"},
		"a comment first":               {title: `<!-- t -->Romeo and Juliet`, want: "Romeo and Juliet"},
		"a processing instruction":      {title: `Romeo and <?editor note?>Juliet`, want: "Romeo and Juliet"},
		"an escaped character":          {title: `Romeo &amp; Juliet`, want: "Romeo & Juliet"},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			score, err := parseString(t, exportedScore{work: `<work-title>` + tt.title + `</work-title>`}.String())
			if err != nil {
				t.Fatalf("failed to parse: %v", err)
			}
			if score.Work == nil || score.Work.Title != tt.want {
				t.Errorf("Work = %+v, want the title %q", score.Work, tt.want)
			}
		})
	}

	t.Run("in a creator", func(t *testing.T) {
		score, err := parseString(t, exportedScore{
			identification: `<creator type="composer"><!-- from catalogue -->Ludwig <![CDATA[van]]> Beethoven</creator>`,
		}.String())
		if err != nil {
			t.Fatalf("failed to parse: %v", err)
		}
		assertStrings(t, "composers", creatorsOfType(score, "composer"), []string{"Ludwig van Beethoven"})
	})
}

// TestDeserializeRejectsWhatIsNotAScore is the other side of skipping what is
// not known: a document that is not well-formed, or not a partwise score at all,
// is still refused.
func TestDeserializeRejectsWhatIsNotAScore(t *testing.T) {
	tests := map[string]string{
		"another kind of document":                                  `<html><body>not a score</body></html>`,
		"a timewise score":                                          `<score-timewise version="4.0"><work><work-title>T</work-title></work></score-timewise>`,
		"something next to the score":                               `<score-partwise version="4.0"><work><work-title>T</work-title></work></score-partwise><extra/>`,
		"an element left open":                                      `<score-partwise version="4.0"><work><work-title>T</work-title></work>`,
		"elements closed out of order":                              `<score-partwise version="4.0"><work><work-title>T</work></work-title></score-partwise>`,
		"an element closed out of order inside one that is skipped": `<score-partwise version="4.0"><defaults><concert-score><a></concert-score></a></defaults></score-partwise>`,
		"text where an element should be":                           `<score-partwise version="4.0"><work>T</work></score-partwise>`,
		"an element inside a title":                                 `<score-partwise version="4.0"><work><work-title>T<b>old</b></work-title></work></score-partwise>`,
		"nothing at all":                                            ``,
	}

	for name, doc := range tests {
		t.Run(name, func(t *testing.T) {
			if _, err := parseString(t, doc); err == nil {
				t.Errorf("parsing %s succeeded, want an error", name)
			}
		})
	}
}

func TestDeserializeRejectsDuplicateFields(t *testing.T) {
	doc := `<score-partwise version="4.0">
		<work><work-title>First</work-title><work-title>Second</work-title></work>
	</score-partwise>`

	if _, err := parseString(t, doc); err == nil {
		t.Error("parsing a document with a repeated <work-title> succeeded, want an error")
	}
}

func TestDeserializeSkipsMusicalContent(t *testing.T) {
	// <part> holds the actual notes; the metadata parser is expected to skip
	// over it rather than choke on the thousands of elements inside.
	doc := `<score-partwise version="4.0">
  <movement-title>Skips Parts</movement-title>
  <part-list>
    <score-part id="P1">
      <part-name>Voice</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Voice</instrument-name>
        <instrument-sound>voice.vocals</instrument-sound>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1"><measure number="1"><note><pitch><step>C</step><octave>4</octave></pitch></note></measure></part>
</score-partwise>`

	score, err := parseString(t, doc)
	if err != nil {
		t.Fatalf("failed to parse a document containing musical content: %v", err)
	}
	if got, want := score.MovementTitle, "Skips Parts"; got != want {
		t.Errorf("MovementTitle = %q, want %q", got, want)
	}
	assertStrings(t, "instrument sounds", instrumentSounds(score), []string{"voice.vocals"})
}

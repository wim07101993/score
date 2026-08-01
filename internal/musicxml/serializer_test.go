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

func TestDeserializeRejectsUnknownElements(t *testing.T) {
	doc := `<score-partwise version="4.0"><not-a-musicxml-element/></score-partwise>`

	if _, err := parseString(t, doc); err == nil {
		t.Error("parsing a document with an unknown element succeeded, want an error")
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

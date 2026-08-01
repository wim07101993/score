package helpers

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

// exampleDataDir holds real-world documents, relative to the package running
// the tests.
const exampleDataDir = "../example_data"

const (
	// ExampleWithWork carries a <work> element and no movement.
	ExampleWithWork = "BeetAnGeSample.musicxml"
	// ExampleWithoutWork carries a <movement-title> and no <work> element at
	// all, which is just as valid.
	ExampleWithoutWork = "BrahWiMeSample.musicxml"
)

// ExampleMusicXml reads one of the sample documents that ship with the repo.
func ExampleMusicXml(t *testing.T, name string) string {
	t.Helper()

	bs, err := os.ReadFile(filepath.Join(exampleDataDir, name))
	require.NoErrorf(t, err, "failed to read the example document %s", name)
	return string(bs)
}

// MusicXmlWithWorkAndMovement is a document that fills in every metadata field
// the API extracts, with values that cannot be mistaken for one another.
const MusicXmlWithWorkAndMovement = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <work>
    <work-number>Work number 41</work-number>
    <work-title>Work title</work-title>
  </work>
  <movement-number>Movement number 2</movement-number>
  <movement-title>Movement title</movement-title>
  <identification>
    <creator type="composer">Clara Composer</creator>
    <creator type="lyricist">Larry Lyricist</creator>
  </identification>
  <defaults>
    <lyric-language xml:lang="nl"/>
  </defaults>
  <part-list>
    <score-part id="P1">
      <part-name>Voice</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Voice</instrument-name>
        <instrument-sound>voice.vocals</instrument-sound>
      </score-instrument>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
</score-partwise>`

// MusicXmlWithTwoComposers checks that every creator of a kind is kept.
const MusicXmlWithTwoComposers = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <work>
    <work-title>Collaboration</work-title>
  </work>
  <identification>
    <creator type="composer">First Composer</creator>
    <creator type="composer">Second Composer</creator>
    <creator type="lyricist">Only Lyricist</creator>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Voice</part-name>
    </score-part>
  </part-list>
</score-partwise>`

// MusicXmlWithUnknownInstrument names an instrument sound that is not part of
// the instrument enum in the database.
const MusicXmlWithUnknownInstrument = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <work>
    <work-title>Unknown instrument</work-title>
  </work>
  <part-list>
    <score-part id="P1">
      <part-name>Kazoo orchestra</part-name>
      <score-instrument id="P1-I1">
        <instrument-name>Kazoo orchestra</instrument-name>
        <instrument-sound>not.a.real.instrument.sound</instrument-sound>
      </score-instrument>
    </score-part>
  </part-list>
</score-partwise>`

// NotMusicXml is well-formed XML that is not a score.
const NotMusicXml = `<?xml version="1.0" encoding="UTF-8"?>
<shopping-list><item>Manuscript paper</item></shopping-list>`

// MalformedXml does not parse as XML at all.
const MalformedXml = `<?xml version="1.0" encoding="UTF-8"?><score-partwise version="4.0"><work>`

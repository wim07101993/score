package musicxml

import (
	"fmt"
	"math"
	"strings"
)

const (
	toneA      Tone = 0
	toneASharp Tone = 1
	toneBFlat       = toneASharp
	toneB      Tone = 2
	toneC      Tone = 3
	toneCSharp Tone = 4
	toneDFlat       = toneCSharp
	toneD      Tone = 5
	toneDSharp Tone = 6
	toneEFlat       = toneDSharp
	toneE      Tone = 7
	toneF      Tone = 8
	toneFSharp Tone = 9
	toneGFlat       = toneFSharp
	toneG      Tone = 10
	toneGSharp Tone = 11
	toneAFlat       = toneGSharp
	toneCount       = toneGSharp + 1
)

type Tone int

func (s *ScorePartwise) Transpose(interval Tone) error {
	for _, p := range s.Parts {
		if err := p.Transpose(interval); err != nil {
			return err
		}
	}
	return nil
}

func (p *Part) Transpose(interval Tone) error {
	var scoreKey Key
	var keyContext Fifths
	for _, m := range p.Measures {
		for _, element := range m.Elements {
			if element.Attributes != nil && element.Attributes.Key != nil {
				scoreKey = *element.Attributes.Key
				keyContext = element.Attributes.Key.Fifths
			}

			if element.Harmony != nil {
				tone := stepAndAlterToTone(element.Harmony.Root.Step, element.Harmony.Root.Alter)
				tone += interval % toneCount
				var err error
				element.Harmony.Root.Step, element.Harmony.Root.Alter, err = tone.toStepAndAlter(scoreKey.Fifths)
				if err != nil {
					return err
				}
				keyContext, err = harmonyToFifths(element.Harmony)
			}
			if element.Note != nil {
				tone := stepAndAlterToTone(element.Note.Pitch.Step, element.Note.Pitch.Alter)
				tone += interval % toneCount
				element.Note.Pitch.Octave += int(interval / toneCount)
				var err error
				element.Note.Pitch.Step, element.Note.Pitch.Alter, err = tone.toStepAndAlter(keyContext)
				if err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func stepAndAlterToTone(step Step, alter float32) Tone {
	var tone Tone
	switch step {
	case "A":
		tone = toneA
	case "B":
		tone = toneB
	case "C":
		tone = toneC
	case "D":
		tone = toneD
	case "E":
		tone = toneE
	case "F":
		tone = toneF
	case "G":
		tone = toneG
	}

	if alter > 0 {
		tone += 1
	} else if alter < 0 {
		tone -= 1
	}

	tone %= toneGSharp + 1
	if tone < 0 {
		tone += toneGSharp + 1
	}

	return tone
}

func (i Tone) toStepAndAlter(context Fifths) (step Step, alter float32, err error) {
	switch i {
	case toneA:
		return "A", 0, nil
	case toneB:
		return "B", 0, nil
	case toneC:
		return "C", 0, nil
	case toneD:
		return "D", 0, nil
	case toneE:
		return "E", 0, nil
	case toneF:
		return "F", 0, nil
	case toneG:
		return "G", 0, nil
	case toneBFlat: // or A#
		if context >= 5 {
			return "A", 1, nil
		}
		return "B", -1, nil
	case toneEFlat: // or D#
		if context >= 4 {
			return "D", 1, nil
		}
		return "E", -1, nil
	case toneAFlat: // or G#
		if context >= 3 {
			return "G", 1, nil
		}
		return "A", -1, nil
	case toneDFlat: // or C#
		if context <= -4 {
			return "D", -1, nil
		}
		return "C", 1, nil
	case toneGFlat: // or F#
		if context <= -5 {
			return "G", -1, nil
		}
		return "F", 1, nil
	default:
		return "", 0, fmt.Errorf("unable to convert tone to harmony (tone %v, key %v)", i, key)
	}
}

func harmonyToFifths(harmony *Harmony) (Fifths, error) {
	var f Fifths
	if strings.HasPrefix(harmony.Kind, "minor") {
		switch harmony.Root.Step {
		case "A":
			f = 0
		case "B":
			f = 2
		case "C":
			f = -3
		case "D":
			f = -1
		case "E":
			f = 1
		case "F":
			f = -4
		case "G":
			f = -2
		default:
			return 0, fmt.Errorf("unknown harmony")
		}
	} else {
		switch harmony.Root.Step {
		case "A":
			f = 3
		case "B":
			f = 5
		case "C":
			f = 0
		case "D":
			f = 2
		case "E":
			f = 4
		case "F":
			f = -1
		case "G":
			f = 1
		}
	}
	f -= Fifths(math.Round(float64(harmony.Root.Alter) * 5))
	return f, nil
}

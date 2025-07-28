package musicxml

import (
	"fmt"
	"slices"
)

type PartFinder func(part *ScorePart) bool

func (score *ScorePartwise) RemoveParts(finder PartFinder) {
	var ids []string
	for start := 0; start < len(score.PartList); start++ {
		p := score.PartList[start]
		if p.ScorePart == nil || !finder(p.ScorePart) {
			continue
		}

		ids = append(ids, p.ScorePart.Id)
		end := start
		fmt.Println("found part", p.ScorePart)

		for {
			if start-1 < 0 || end+2 > len(score.PartList) {
				break
			}
			previous := score.PartList[start-1].PartGroup
			next := score.PartList[end+1].PartGroup
			isPgEmpty := previous != nil && next != nil &&
				previous.Type == PartGroupType_Start && next.Type == PartGroupType_Stop &&
				previous.Number == next.Number
			if !isPgEmpty {
				break
			}
			fmt.Println("found empty group", previous, next)
			start--
			end++
		}

		score.PartList = append(score.PartList[:start], score.PartList[end+1:]...)
	}

	if len(ids) == 0 {
		return
	}

	for i := 0; i < len(score.Parts); i++ {
		if slices.Contains(ids, score.Parts[i].Id) {
			score.Parts[i] = score.Parts[len(score.Parts)-1]
			score.Parts = score.Parts[:len(score.Parts)-1]
			i--
		}
	}
}

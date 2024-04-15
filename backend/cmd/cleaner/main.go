package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"score/backend/pkgs/musicxml"
	"slices"
	"strings"
)

var dirPath string
var clarinet bool
var voice bool
var transMelody bool

func init() {
	flag.StringVar(&dirPath, "dir", "", "The path to the directory which should be cleaned")
	flag.BoolVar(&clarinet, "clarinet", false, "True: remove the clarinet part")
	flag.BoolVar(&voice, "voice", false, "True: remove the voice part")
	flag.BoolVar(&transMelody, "trans-melody", false, "True: remove the Bb-melody part")
}

func main() {
	flag.Parse()
	validateVars()

	entries, err := os.ReadDir(dirPath)
	panicErr(err)

	for _, entry := range entries {
		filename := entry.Name()
		if strings.HasSuffix(filename, ".musicxml") {
			cleanScore(filepath.Join(dirPath, filename))
		}
	}
}

func cleanScore(path string) {
	fmt.Println(path)
	rFile, err := os.Open(path)
	panicErr(err)

	reader := xml.NewDecoder(rFile)
	score, err := musicxml.DeserializeMusicXml(reader)
	panicErr(err)

	err = rFile.Close()
	panicErr(err)

	if clarinet {
		removePart(score, "Clarinet")
	}
	if voice {
		removePart(score, "Voice")
	}
	if transMelody {
		removePart(score, "Melody in")
	}

	cleanupPartList(score)

	wFile, err := os.Create(path)
	panicErr(err)
	defer func() {
		panicErr(wFile.Close())
	}()

	writer := xml.NewEncoder(wFile)
	writer.Indent("", " ")
	err = musicxml.SerializeMusixXml(writer, score)
	defer func() {
		panicErr(writer.Close())
	}()
	panicErr(err)
}

func cleanupPartList(score *musicxml.ScorePartwise) {
	var toRemove []int
	for i, p := range score.PartList {
		if p.PartGroup != nil {
			switch p.PartGroup.Type {
			case musicxml.PartGroupType_Start:
				if len(score.PartList) > i+1 {
					p2 := score.PartList[i+1]
					if p2.PartGroup != nil &&
						p.PartGroup.Number == p2.PartGroup.Number &&
						p2.PartGroup.Type == musicxml.PartGroupType_Stop {
						toRemove = append(toRemove, p.PartGroup.Number)
					}
				}
			}
		}
	}
	if len(toRemove) < 0 {
		return
	}

	for _, id := range toRemove {
		i := slices.IndexFunc(score.PartList, func(item musicxml.PartListItem) bool {
			if item.PartGroup == nil {
				return false
			}
			return item.PartGroup.Number == id
		})
		score.PartList = append(score.PartList[:i], score.PartList[i+2:]...)
	}
}

func removePart(score *musicxml.ScorePartwise, name string) {
	var id string
	name = strings.ToLower(name)
	for i, p := range score.PartList {
		if p.ScorePart == nil {
			continue
		}
		n := strings.ToLower(p.ScorePart.Name)
		if !strings.HasPrefix(n, name) {
			continue
		}

		id = p.ScorePart.Id
		score.PartList = append(score.PartList[:i], score.PartList[i+1:]...)
		break
	}

	if id == "" {
		return
	}

	for i, p := range score.Parts {
		if p.Id == id {
			score.Parts[i] = score.Parts[len(score.Parts)-1]
			score.Parts = score.Parts[:len(score.Parts)-1]
			break
		}
	}
}

func panicErr(err error) {
	if err != nil {
		panic(err)
	}
}

func validateVars() {
	if dirPath == "" {
		panic("no dirPath specified to clean")
	}
}

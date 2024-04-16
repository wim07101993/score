package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"score/backend/pkgs/musicxml"
	"strings"
)

var dirPath string
var voice bool
var transMelody bool

func init() {
	flag.StringVar(&dirPath, "dir", "", "The path to the directory which should be cleaned")
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

	if voice {
		score.RemoveParts(func(part *musicxml.ScorePart) bool {
			return part.Name == "Voice"
		})
	}
	if transMelody {
		score.RemoveParts(func(part *musicxml.ScorePart) bool {
			return strings.HasPrefix(part.Name, "Melody in ")
		})
	}

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

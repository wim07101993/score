package main

import (
	"encoding/xml"
	"flag"
	"os"
	"score/backend/pkgs/musicxml"
)

var opts struct {
	path       string
	removePart string
	transpose  int
}

func init() {
	flag.StringVar(&opts.path, "path", ".", "path to the musicxml file")
	flag.StringVar(&opts.removePart, "remove", "", "part to remove from the score")
	flag.IntVar(&opts.transpose, "transpose", 0, "interval to transpose the score by")
}

func main() {
	flag.Parse()
	validateVars()

	score := getScore()

	if opts.removePart != "" {
		score.RemoveParts(func(part *musicxml.ScorePart) bool {
			return part.Name == opts.removePart
		})
	}

	if opts.transpose != 0 {
		if err := score.Transpose(musicxml.Tone(opts.transpose)); err != nil {
			panic(err)
		}
	}

	writeScore(score)
}

func getScore() *musicxml.ScorePartwise {
	var err error
	var file *os.File
	if file, err = os.Open(opts.path); err != nil {
		panic(err)
	}

	decoder := xml.NewDecoder(file)
	var score *musicxml.ScorePartwise
	if score, err = musicxml.DeserializeMusicXml(decoder); err != nil {
		panic(err)
	}

	if err = file.Close(); err != nil {
		panic(err)
	}

	return score
}

func writeScore(score *musicxml.ScorePartwise) {
	file, err := os.Create(opts.path)
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := file.Close(); err != nil {
			panic(err)
		}
	}()

	encoder := xml.NewEncoder(file)
	defer func() {
		if err := file.Close(); err != nil {
			panic(err)
		}
	}()
	encoder.Indent("", " ")

	if err = musicxml.SerializeMusixXml(encoder, score); err != nil {
		panic(err)
	}

}

func validateVars() {
	if opts.path == "" {
		panic("no file path to score specified")
	}
}

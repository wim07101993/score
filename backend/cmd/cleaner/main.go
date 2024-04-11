package main

import (
	"encoding/xml"
	"fmt"
	"os"
	"path"
	"score/backend/pkgs/musicxml"
)

func main() {
	const dir = "/home/wim/scores/scores"
	entries, err := os.ReadDir(dir)
	panicErr(err)

	for _, entry := range entries {
		fmt.Println(entry)
		if entry.IsDir() {
			break
		}

		cleanFile(path.Join(dir, entry.Name()))
	}

}

func cleanFile(path string) {
	rFile, err := os.Open(path)
	panicErr(err)

	reader := xml.NewDecoder(rFile)
	score, err := musicxml.DeserializeMusicXml(reader)
	panicErr(err)

	err = rFile.Close()
	panicErr(err)

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

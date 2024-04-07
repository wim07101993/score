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
		return
	}

}

func cleanFile(path string) {
	rFile, err := os.Open(path)
	panicErr(err)
	defer func() {
		panicErr(rFile.Close())
	}()

	reader := xml.NewDecoder(rFile)
	score, err := musicxml.DeserializeMusicXml(reader)
	panicErr(err)

	wFile, err := os.OpenFile(fmt.Sprint(path), os.O_CREATE|os.O_RDWR, 777)
	panicErr(err)
	defer func() {
		panicErr(wFile.Close())
	}()

	writer := xml.NewEncoder(wFile)
	writer.Indent("", "  ")
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

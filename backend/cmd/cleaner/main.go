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

		file, err := os.Open(path.Join(dir, entry.Name()))
		panicErr(err)

		reader := xml.NewDecoder(file)
		score, err := musicxml.DeserializeMusicXml(reader)
		panicErr(err)
		fmt.Println(score)
	}

}

func panicErr(err error) {
	if err != nil {
		panic(err)
	}
}

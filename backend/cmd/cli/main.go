package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"score/backend/pkgs/musicxml"
)

var filePath = flag.String("file", "", "the file to parse")

func main() {
	flag.Parse()

	if filePath == nil || *filePath == "" {
		log.Fatalln("a file to parse must be provided")
	}

	f, err := os.Open(*filePath)
	if err != nil {
		log.Fatalf("error while reading file: %v", err)
	}
	music, err := musicxml.ParseMusicXml(f)
	if err != nil {
		log.Fatalf("error while parsing the file: %v", err)
	}
	log.Printf("read file: %v\n", music.Work.WorkTitle)
	fmt.Println(len(music.Parts))
	for _, p := range music.Parts {
		fmt.Println(len(p.Measure))
	}
	fmt.Println(music.Defaults.Scaling.Millimeters)
	fmt.Println(music.Version)
	fmt.Println(music.Identification.Creator[0])
	fmt.Println(music.Identification.Encoding.Encoder[0])
	fmt.Println(music.Identification.Encoding.SupportedFeatures[1])
}

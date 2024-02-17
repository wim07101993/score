package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"log"
	"os"
	"score/backend/pkgs/models"
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

	d := xml.NewDecoder(f)
	p := models.MusicXmlParser{}
	s, err := p.FromXml(d)
	if err != nil {
		panic(err)
	}
	fmt.Println(s)
}

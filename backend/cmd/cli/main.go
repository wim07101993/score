package main

import (
	"encoding/json"
	"encoding/xml"
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

	d := xml.NewDecoder(f)
	p := musicxml.Parser{}
	s, err := p.FromXml(d)

	fmt.Println()
	j, _ := json.MarshalIndent(s, "", "\t")
	fmt.Printf("%s\n", j)
	if err != nil {
		panic(err)
	}
}

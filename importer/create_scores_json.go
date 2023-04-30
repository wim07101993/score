package main

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"strings"
)

const RootDir = "/home/wim/OneDrive/SheetMusic/"

func init() {
	//ctx := context.Background()
	//conf := &firebase.Config{ProjectID: "score-e5588"}
	//app, err := firebase.NewApp(ctx, conf)
	//if err != nil {
	//	log.Fatalln(err)
	//}
	//
	//client, err := app.Firestore(ctx)
	//if err != nil {
	//	log.Fatalln(err)
	//}
	//defer client.Close()
}

func createScoresJson() {
	var scores Scores
	err := filepath.Walk(RootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Println(err)
		}
		if strings.Contains(path, "__busy") {
			return nil
		}

		if info.IsDir() {
			return nil
		}
		s := DirectoryPathToScore(path)
		partDescription := s.partDescription()
		if partDescription == "" || partDescription == "Voice" || partDescription == "Score and parts" || partDescription == s.Title {
			println("skip " + s.Title + " " + partDescription)
			return nil
		}
		scores = scores.Add(s)
		return nil
	})
	if err != nil {
		log.Fatalln(err)
	}

	j, err := json.MarshalIndent(scores, "", "  ")
	if err != nil {
		log.Fatalln(err)
	}

	err = os.WriteFile("scores.json", j, 777)
	if err != nil {
		log.Fatalln(err)
	}
	//log.Println(string(j))
}

type ScoreFile struct {
	Title       string
	Arrangement string
	Composers   []string
	Instruments []string
	Link        string
}

func (f ScoreFile) partDescription() string {
	return strings.Join(f.Instruments, ", ")
}

func DirectoryPathToScore(path string) ScoreFile {
	noRoot := path[len(RootDir):]
	score := ScoreFile{
		Link: path,
	}
	segments := strings.SplitN(noRoot, "/", 4)
	// Composers directory names formatted as "asdlkf - asdf"
	score.Composers = splitByMultiple(segments[0], []string{" - ", ", ", " & "})
	// songs are listed as directories in the composer's directory
	score.Title = segments[1]

	var fileName string
	if len(segments) > 3 {
		// some songs have special variants like oase
		score.Arrangement = segments[2]
		fileName = segments[3]
	} else {
		fileName = segments[2]
	}

	// the Instruments are listed at the end of a Link name, before the extension like:
	// Nkembo - Soprano, Alto, Tenor, Baritone A5_001.png
	split := strings.Split(fileName, ".")
	if split[1] != "sib" {
		withoutA5Suffix := strings.Replace(strings.Split(split[0], "_")[0], " A5", "", -1)
		split = strings.Split(withoutA5Suffix, " - ")
		score.Instruments = strings.Split(split[len(split)-1], ", ")
	} else {
		score.Instruments = []string{}
	}

	return score
}

func AreStringsTheSame(ss1 []string, ss2 []string) bool {
	if len(ss1) != len(ss2) {
		return false
	}
	for i, c := range ss1 {
		if c != ss2[i] {
			return false
		}
	}
	return true
}

func splitByMultiple(s string, delimiters []string) []string {
	if len(delimiters) == 0 {
		return []string{s}
	}
	ss := strings.Split(s, delimiters[0])
	for _, d := range delimiters[1:] {
		var newss []string
		for _, s := range ss {
			newss = append(newss, strings.Split(s, d)...)
		}
		ss = newss
	}
	return ss
}

type Scores []Score
type Score struct {
	Title        string
	Composers    []string
	Arrangements Arrangements
}

type Arrangements []Arrangement
type Arrangement struct {
	Name      string
	Parts     ArrangementParts
	Lyricists []string
}

type ArrangementParts []ArrangementPart
type ArrangementPart struct {
	Description string
	Links       []string
	Instruments []string
}

func (ss Scores) Add(s ScoreFile) Scores {
	si := ss.Find(s.Title, s.Composers)
	if si == -1 {
		return append(ss, Score{
			Title:        s.Title,
			Composers:    s.Composers,
			Arrangements: Arrangements{}.Add(s),
		})
	}
	ss[si].Arrangements = ss[si].Arrangements.Add(s)
	return ss
}

func (ss Scores) Find(title string, composers []string) int {
	for i := 0; i < len(ss); i++ {
		if ss[i].Title == title && AreStringsTheSame(composers, ss[i].Composers) {
			return i
		}
	}
	return -1
}

func (as Arrangements) Add(s ScoreFile) Arrangements {
	ai := as.Find(s)
	if ai < 0 {
		return append(as, Arrangement{
			Name:      s.Arrangement,
			Lyricists: s.Composers,
			Parts:     ArrangementParts{}.Add(s),
		})
	}
	as[ai].Parts = as[ai].Parts.Add(s)
	return as
}

func (as Arrangements) Find(s ScoreFile) int {
	for i := 0; i < len(as); i++ {
		if as[i].Name == s.Arrangement {
			return i
		}
	}
	return -1
}

func (ps ArrangementParts) Add(s ScoreFile) ArrangementParts {
	pi := ps.Find(s)
	if pi < 0 {
		return append(ps, ArrangementPart{
			Description: s.partDescription(),
			Links:       []string{s.Link},
			Instruments: s.Instruments,
		})
	}
	ps[pi].Links = append(ps[pi].Links, s.Link)
	return ps
}

func (ps ArrangementParts) Find(s ScoreFile) int {
	d := s.partDescription()
	for i, p := range ps {
		if p.Description == d {
			return i
		}
	}
	return -1
}

package musicxml

import "encoding/xml"

type Notation struct {
	Slurs         []*Slur
	Ties          []*Tied
	Tuplets       []*Tuplet
	Dynamics      []*Dynamic
	Fermatas      []*Fermata
	Articulations []*Articulations
	Slides        []*Slide
	Arpeggiate    []*Arpeggiate
	Technical     []*Technical
	Glissandos    []*Glissando
}

func readNotation(r xml.TokenReader, element xml.StartElement) (notation *Notation, err error) {
	notation = &Notation{}
	err = ReadObject(r, element,
		func(attr xml.Attr) error {
			return &UnknownAttribute{element, attr}
		},
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "tied":
				tie, err := readTied(r, el)
				if err != nil {
					return err
				}
				notation.Ties = append(notation.Ties, tie)
			case "slur":
				slur, err := readSlur(r, el)
				if err != nil {
					return err
				}
				notation.Slurs = append(notation.Slurs, slur)
			case "tuplet":
				tuplet, err := readTuplet(r, el)
				if err != nil {
					return err
				}
				notation.Tuplets = append(notation.Tuplets, tuplet)
			case "fermata":
				fermata, err := readFermata(r, el)
				if err != nil {
					return err
				}
				notation.Fermatas = append(notation.Fermatas, fermata)
			case "dynamics":
				dynamic, err := readDynamic(r, el)
				if err != nil {
					return err
				}
				notation.Dynamics = append(notation.Dynamics, dynamic)
			case "articulations":
				articulations, err := readArticulations(r, el)
				if err != nil {
					return err
				}
				notation.Articulations = append(notation.Articulations, articulations)
			case "slide":
				slide, err := readSlide(r, el)
				if err != nil {
					return err
				}
				notation.Slides = append(notation.Slides, slide)
			case "arpeggiate":
				apr, err := readArpeggiate(r, el)
				if err != nil {
					return err
				}
				notation.Arpeggiate = append(notation.Arpeggiate, apr)
			case "technical":
				tech, err := readTechnical(r, el)
				if err != nil {
					return err
				}
				notation.Technical = append(notation.Technical, tech)
			case "glissando":
				glissando, err := readGlissando(r, el)
				if err != nil {
					return err
				}
				notation.Glissandos = append(notation.Glissandos, glissando)
			default:
				return &UnknownElement{element, el}
			}
			return err
		})
	return notation, err
}

func writeNotation(w *xml.Encoder, name string, notation *Notation) (err error) {
	return WriteObject(w, name, nil,
		func() error {
			for _, tie := range notation.Ties {
				if err = writeTied(w, "tied", tie); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, slur := range notation.Slurs {
				if err = writeSlur(w, "slur", slur); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, tuplet := range notation.Tuplets {
				if err = writeTuplet(w, "tuplet", tuplet); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, fermata := range notation.Fermatas {
				if err = writeFermata(w, "fermata", fermata); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, dynamic := range notation.Dynamics {
				if err = writeDynamic(w, "dynamics", dynamic); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, articulation := range notation.Articulations {
				if err = writeArticulation(w, "articulations", articulation); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, slide := range notation.Slides {
				if err = writeSlide(w, "slide", slide); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, arpeggiate := range notation.Arpeggiate {
				if err = writeArpeggiate(w, "arpeggiate", arpeggiate); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, technical := range notation.Technical {
				if err = writeTechnical(w, "technical", technical); err != nil {
					return err
				}
			}
			return nil
		},
		func() error {
			for _, glissando := range notation.Glissandos {
				if err = writeGlissando(w, "glissando", glissando); err != nil {
					return err
				}
			}
			return nil
		})
}

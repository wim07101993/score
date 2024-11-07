package search

import (
	"encoding/xml"
	"fmt"
	"score/backend/pkgs/musicxml"
)

func ParseScore(r xml.TokenReader) (*Score, error) {
	root := xml.StartElement{Name: xml.Name{Local: "root"}}
	var score *Score
	err := musicxml.ReadObject(r, root, nil, func(el xml.StartElement) error {
		var err error
		switch el.Name.Local {
		case "score-partwise":
			score, err = parseScorePartwise(r, el)
		default:
			err = musicxml.ReadUntilClose(r, el)
		}
		return err
	})
	return score, err
}

func parseScorePartwise(r xml.TokenReader, start xml.StartElement) (*Score, error) {
	score := &Score{}
	err := musicxml.ReadObject(r, start,
		nil,
		func(el xml.StartElement) error {
			switch el.Name.Local {
			case "work":
				return musicxml.ReadObject(r, el, nil, func(el2 xml.StartElement) error {
					var err error
					switch el2.Name.Local {
					case "work-title":
						score.Title, err = musicxml.ReadString(r, el2)
					default:
						err = musicxml.ReadUntilClose(r, el2)
					}
					return err
				})
			case "identification":
				return musicxml.ReadObject(r, el, nil, func(el2 xml.StartElement) error {
					switch el2.Name.Local {
					case "creator":
						return parseCreatorIntoScore(r, el2, score)
					default:
						return musicxml.ReadUntilClose(r, el2)
					}
				})
			case "part-list":
				return musicxml.ReadObject(r, el, nil, func(el2 xml.StartElement) error {
					switch el2.Name.Local {
					case "score-part":
						return musicxml.ReadObject(r, el2, nil, func(el3 xml.StartElement) error {
							switch el3.Name.Local {
							case "score-instrument":
								return musicxml.ReadObject(r, el3, nil, func(el4 xml.StartElement) error {
									switch el4.Name.Local {
									case "instrument-name":
										instr, err := musicxml.ReadString(r, el4)
										if err != nil {
											return err
										}
										if score.Instruments != "" {
											score.Instruments += ", "
										}
										score.Instruments += instr
										return nil
									default:
										return musicxml.ReadUntilClose(r, el4)
									}
								})
							default:
								return musicxml.ReadUntilClose(r, el3)
							}
						})
					default:
						return musicxml.ReadUntilClose(r, el2)
					}
				})
			default:
				return musicxml.ReadUntilClose(r, el)
			}
		})
	return score, err
}

func parseCreatorIntoScore(r xml.TokenReader, start xml.StartElement, score *Score) error {
	t, err := r.Token()
	if err != nil {
		return err
	}

	var val string
	switch el := t.(type) {
	case xml.CharData:
		val = string(el)
	default:
		return &musicxml.UnexpectedTokenError{Element: start, Token: t}
	}

	err = musicxml.ReadUntilClose(r, start)
	if err != nil {
		return err
	}

	if val == "" {
		return nil
	}

	for _, attr := range start.Attr {
		switch attr.Name.Local {
		case "type":
			switch attr.Value {
			case "composer":
				if score.Composers != "" {
					score.Composers += ", "
				}
				score.Composers += val
			case "lyricist":
				if score.Lyricists != "" {
					score.Lyricists += ", "
				}
				score.Lyricists = val
			case "arranger":
				// IGNORE ARRANGERS FOR THE SEARCH MODEL
				break
			default:
				return fmt.Errorf("unknown creator type %v", attr)
			}
		}
	}
	return nil
}

package musicxml

//import "encoding/xml"
//
//type ScorePartwise struct {
//	Work           Work           `xml:"work"`
//	Identification Identification `xml:"identification"`
//	PartList       PartList       `xml:"part-list"`
//	Parts          []Part         `xml:"part"`
//}
//
//type Work struct {
//	Title string `xml:"work-title"`
//}
//
//type Identification struct {
//	Creators []Creator `xml:"creator"`
//}
//
//type Creator struct {
//	Type  string `xml:"type,attr"`
//	Value string `xml:",chardata"`
//}
//
//type PartList struct {
//	Items []PartListItem `xml:",any"`
//}
//
//type PartListItem any
//
//type PartGroup struct {
//	XMLName     xml.Name `xml:"part-group"`
//	Type        string   `xml:"type,attr"`
//	Number      int      `xml:"number,attr"`
//	GroupSymbol string   `xml:"group-symbol"`
//}
//
//type ScorePart struct {
//	XMLName                 xml.Name        `xml:"score-part"`
//	Id                      string          `xml:"id,attr"`
//	Name                    string          `xml:"part-name"`
//	NameDisplay             NameDisplay     `xml:"part-name-display"`
//	PartAbbreviation        string          `xml:"part-abbreviation"`
//	PartAbbreviationDisplay NameDisplay     `xml:"part-abbreviation-display"`
//	Instrument              ScoreInstrument `xml:"score-instrument"`
//}
//
//type NameDisplay struct {
//	DisplayText string `xml:"display-text"`
//}
//
//type ScoreInstrument struct {
//	Id   string `xml:"id,attr"`
//	Name string `xml:"instrument-name"`
//}
//
//type Part struct {
//	// TODO figure this out
//}

package models

type PartGroup struct {
	Id         string
	Symbol     string
	PartGroups []*PartGroup
	Parts      []*Part
}

type Part struct {
	Id                  string
	Name                string
	NameDisplay         string
	Abbreviation        string
	AbbreviationDisplay string
	Instrument          string
	Measures            []*Measure
}

func (pg *PartGroup) Part(partId string) *Part {
	for _, p := range pg.Parts {
		if p != nil && p.Id == partId {
			return p
		}
	}
	for _, pg := range pg.PartGroups {
		if pt := pg.Part(partId); pt != nil {
			return pt
		}
	}
	return nil
}

func (pg *PartGroup) Instruments() []string {
	var instrs []string
	for _, p := range pg.Parts {
		if p.Instrument != "" {
			instrs = append(instrs, p.Instrument)
		}
	}
	for _, pg2 := range pg.PartGroups {
		instrs = append(instrs, pg2.Instruments()...)
	}
	return instrs
}

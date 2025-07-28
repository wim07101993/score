package musicxml

type MeasureElement struct {
	Attributes *MeasureAttributes
	Direction  *Direction
	Note       *Note
	Barline    *Barline
	Harmony    *Harmony
	Backup     *Backup
	Forward    *Forward
}

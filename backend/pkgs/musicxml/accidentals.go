package musicxml

import (
	"log/slog"
)

func (p *Parser) AccidentalToString(accidental string) string {
	switch accidental {
	case "flat":
		return "♭"
	default:
		p.Logger.Warn("unknown accidental", slog.Any("accidental", accidental))
		return accidental
	}
}

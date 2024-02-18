package musicxml

import "fmt"

func AccidentalToString(accidental string) string {
	switch accidental {
	case "flat":
		return "♭"
	default:
		fmt.Printf("unknown accidental %s\n", accidental)
		return accidental
	}
}

package closer

import (
	"io"
	"log"
)

func CloseAndLogError(c io.Closer) {
	err := c.Close()
	if err != nil {
		log.Fatalf("failed to close connection: %v", err)
	}
}

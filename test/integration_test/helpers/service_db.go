package helpers

import (
	"context"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

// TruncateScores empties the score tables so a test can make assertions about
// everything the API stored, not just about its own rows.
func (h *Harness) TruncateScores(t *testing.T) {
	t.Helper()

	_, err := h.EnsureDatabase(t).Exec(context.Background(),
		"TRUNCATE scores, score_files CASCADE")
	require.NoError(t, err, "failed to truncate the score tables")
}

// CountRows counts the rows of a table with the given id. It is how a test
// checks what the API left behind, including rows no endpoint would ever
// return.
func (h *Harness) CountRows(t *testing.T, table string, id string) int {
	t.Helper()

	var count int
	err := h.EnsureDatabase(t).
		QueryRow(context.Background(), fmt.Sprintf("SELECT count(*) FROM %s WHERE id = $1", table), id).
		Scan(&count)
	require.NoErrorf(t, err, "failed to count rows of %s", table)
	return count
}

package helpers

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

// CountRows counts the rows of a table with the given id. It is how a test
// checks what the API left behind, including rows no endpoint would ever
// return.
//
// It counts by id rather than emptying a table first, so that a test says
// nothing about what the tests running beside it are storing.
func (h *Harness) CountRows(t *testing.T, table string, id string) int {
	t.Helper()

	pool := Ensure(t, h.PgxPool, "database pool")

	var count int
	err := pool.
		QueryRow(t.Context(), fmt.Sprintf("SELECT count(*) FROM %s WHERE id = $1", table), id).
		Scan(&count)
	require.NoErrorf(t, err, "failed to count rows of %s", table)
	return count
}

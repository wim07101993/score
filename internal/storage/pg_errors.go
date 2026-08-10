package storage

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

// The postgres error codes something here acts on, from appendix A of the
// manual: https://www.postgresql.org/docs/current/errcodes-appendix.html
//
// They are unexported, and asked about through the functions below rather than
// compared to. A caller that has the code has to unwrap the error to reach it,
// and the same five lines of unwrapping written next to every query is how one
// of them ends up comparing the wrong thing.
const (
	// pgInvalidTextRepresentation is a value that does not parse as the type of
	// the column it is written to, such as a uuid or an enum member that does
	// not exist.
	pgInvalidTextRepresentation = "22P02"

	// pgForeignKeyViolation is a row pointing at something that is not there.
	pgForeignKeyViolation = "23503"

	// pgUniqueViolation is a row that is already there, under a key something
	// said there could only be one of.
	pgUniqueViolation = "23505"
)

// IsInvalidTextRepresentation reports whether err is postgres refusing a value
// as not being of the column's type.
func IsInvalidTextRepresentation(err error) bool {
	return hasCode(err, pgInvalidTextRepresentation)
}

// IsForeignKeyViolation reports whether err is postgres refusing a row for
// pointing at something that does not exist.
func IsForeignKeyViolation(err error) bool {
	return hasCode(err, pgForeignKeyViolation)
}

// IsUniqueViolation reports whether err is postgres refusing a row for already
// having one under that key.
func IsUniqueViolation(err error) bool {
	return hasCode(err, pgUniqueViolation)
}

func hasCode(err error, code string) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == code
}

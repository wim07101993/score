// Package score is the scores slice of the API: sheet music, and the metadata
// extracted from it when it is uploaded. What it serves is described in
// api/endpoints/scores.
//
// There is a file per operation, and each of them holds everything that
// operation is: what it answers, and how it reads or writes the database. What
// they share — the model of a score, the connection they run on, what can go
// wrong with one — is in scores.go, database.go, model.go and errors.go.
package score

// Handler implements the score operations of the openapi document.
//
// Everything about the shape of those operations — which paths they are, which
// methods they answer, which parameters they read, which roles they ask for and
// what comes back — is in api/endpoints/scores and in the code generated from it.
// What is left here is what they do.
type Handler struct {
	db DatabaseFactory
}

func NewHandler(db DatabaseFactory) *Handler {
	return &Handler{db: db}
}

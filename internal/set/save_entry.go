package set

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"score/internal/storage"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

// SaveEntry puts one score into a set, or changes how it is played, and hands
// the entry back as it now reads.
//
// The set is closed up around it: an entry written at a place the set already
// has an entry in puts that one and everything after it back by one, and an
// entry that is already in the set and is written at another place moves there.
// A place beyond the end of the set is the end of the set rather than a
// refusal — a client catching up after a gig it spent offline is saying where a
// song goes, and the nearest place it can go is a better answer to that than a
// rejected write.
//
// Only the owner of a set can write its entries: what the band plays is the
// set, and the set is theirs. It is ErrSetNotFound for a set that is not there,
// ErrNotSetOwner for one that is somebody else's, ErrUnknownScore for an entry
// pointing at a score that does not exist, and ErrInvalidSetEntry for an entry
// the caller has to fix.
func SaveEntry(
	ctx context.Context,
	db *pgxpool.Conn,
	setId string,
	entryId string,
	user User,
	write WriteEntry,
) (*Entry, error) {
	slogctx.Info(ctx, "saving set entry",
		slog.String("setId", setId), slog.String("entryId", entryId))

	if err := validateEntry(write); err != nil {
		return nil, err
	}

	tx, err := db.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err := requireOwnedSet(ctx, tx, setId, user); err != nil {
		return nil, err
	}

	// An id that is already an entry of another set is refused rather than
	// taken over: it would point this set's entry at what another set's players
	// said about theirs.
	const ownerOfEntryQuery = `SELECT set_id FROM set_entries WHERE id = @entry_id`
	var entryBelongsTo string
	err = tx.QueryRow(ctx, ownerOfEntryQuery, pgx.NamedArgs{"entry_id": entryId}).Scan(&entryBelongsTo)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		entryBelongsTo = ""
	case err != nil:
		return nil, fmt.Errorf("failed to look up the entry: %w", err)
	case entryBelongsTo != setId:
		return nil, &ErrInvalidSetEntry{Reason: "the entry belongs to another set"}
	}

	order, err := entryOrderOf(ctx, tx, setId)
	if err != nil {
		return nil, err
	}

	// Where it ends up: out of the order it is in now, if it is in one, and
	// back into it at the place that was asked for.
	order = without(order, entryId)
	position := min(write.Position, len(order))
	order = insertAt(order, position, entryId)

	if entryBelongsTo == "" {
		const insertQuery = `
			INSERT INTO set_entries (id, set_id, position, score_id, description, transposition)
			VALUES (@id, @set_id, @position, @score_id, @description, @transposition)`
		_, err = tx.Exec(ctx, insertQuery, pgx.NamedArgs{
			"id":     entryId,
			"set_id": setId,
			// Out of everybody's way until the order is written below: the
			// place it is going to is very likely taken at this moment.
			"position":      len(order) + firstFreePosition,
			"score_id":      write.ScoreId,
			"description":   write.Description,
			"transposition": write.Transposition,
		})
	} else {
		const updateQuery = `
			UPDATE set_entries
			SET score_id = @score_id, description = @description, transposition = @transposition
			WHERE id = @id AND set_id = @set_id`
		_, err = tx.Exec(ctx, updateQuery, pgx.NamedArgs{
			"id":            entryId,
			"set_id":        setId,
			"score_id":      write.ScoreId,
			"description":   write.Description,
			"transposition": write.Transposition,
		})
	}
	if err != nil {
		// The only thing a set entry points at is a score, so a row that points
		// at something missing is a score that is not there.
		if storage.IsForeignKeyViolation(err) {
			return nil, &ErrUnknownScore{ScoreId: write.ScoreId}
		}
		return nil, fmt.Errorf("failed to save the entry: %w", err)
	}

	if err := writeEntryOrder(ctx, tx, setId, order); err != nil {
		return nil, err
	}

	// The running order is what everybody the set is shared with plays from, so
	// a change to it is a change to the set for all of them.
	if err := touchSet(ctx, tx, setId); err != nil {
		return nil, err
	}

	view, err := viewOfEntry(ctx, tx, entryId, user)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit the entry: %w", err)
	}

	return &Entry{
		Id:            entryId,
		ScoreId:       write.ScoreId,
		Description:   write.Description,
		Position:      position,
		Transposition: write.Transposition,
		View:          *view,
	}, nil
}

// DeleteEntry takes one score out of a set and closes the running order up
// around it. What every player said about how they look at it goes with it: it
// was about a song that is no longer played.
//
// Only the owner of a set can take an entry out of it. It is ErrSetNotFound for
// a set that is not there, ErrNotSetOwner for one that is somebody else's, and
// ErrSetEntryNotFound for an entry that is not in the set that was named.
func DeleteEntry(
	ctx context.Context,
	db *pgxpool.Conn,
	setId string,
	entryId string,
	user User,
) error {
	slogctx.Info(ctx, "deleting set entry",
		slog.String("setId", setId), slog.String("entryId", entryId))

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err := requireOwnedSet(ctx, tx, setId, user); err != nil {
		return err
	}

	tag, err := tx.Exec(ctx,
		`DELETE FROM set_entries WHERE id = @entry_id AND set_id = @set_id`,
		pgx.NamedArgs{"entry_id": entryId, "set_id": setId})
	if err != nil {
		return fmt.Errorf("failed to delete the entry: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrSetEntryNotFound
	}

	order, err := entryOrderOf(ctx, tx, setId)
	if err != nil {
		return err
	}
	if err := writeEntryOrder(ctx, tx, setId, order); err != nil {
		return err
	}

	if err := touchSet(ctx, tx, setId); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the deletion: %w", err)
	}
	return nil
}

// firstFreePosition is how far past the end of a set a row is parked while it
// is being put in its place. Positions are unique within a set, and a row being
// inserted has to sit somewhere until the whole order is written; anywhere past
// the end will do, since nothing else is ever there.
const firstFreePosition = 1

// requireOwnedSet answers whether the caller may arrange this set.
//
// A set that is not there, or has been deleted, is not one to write entries of.
// One that is somebody else's is theirs to arrange — but that is only worth
// saying to somebody who can see it at all: telling a stranger that a set is
// not theirs tells them it exists, so for them it is not there.
func requireOwnedSet(ctx context.Context, tx pgx.Tx, setId string, user User) error {
	const query = `
		SELECT s.owner_subject, (sh.email IS NOT NULL) AS shared
		FROM sets AS s
		LEFT JOIN set_shares AS sh ON sh.set_id = s.id AND sh.email = @email
		WHERE s.id = @id AND s.deletedAt IS NULL`

	var (
		owner  string
		shared bool
	)
	err := tx.QueryRow(ctx, query, pgx.NamedArgs{"id": setId, "email": user.Email}).
		Scan(&owner, &shared)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return ErrSetNotFound
	case err != nil:
		return fmt.Errorf("failed to look up the owner of the set: %w", err)
	case owner == user.Subject:
		return nil
	case shared:
		return ErrNotSetOwner
	default:
		return ErrSetNotFound
	}
}

// entryOrderOf is the entries of a set, in playing order.
func entryOrderOf(ctx context.Context, tx pgx.Tx, setId string) ([]string, error) {
	const query = `SELECT id FROM set_entries WHERE set_id = @set_id ORDER BY position`

	rows, err := tx.Query(ctx, query, pgx.NamedArgs{"set_id": setId})
	if err != nil {
		return nil, fmt.Errorf("failed to read the running order: %w", err)
	}
	defer rows.Close()

	order := make([]string, 0)
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("failed to read the running order: %w", err)
		}
		order = append(order, id)
	}
	return order, rows.Err()
}

// writeEntryOrder numbers the entries of a set nought upwards in the order they
// are given, so that there are never gaps in it.
//
// The rows are shuffled in place, so this passes through moments where two of
// them hold the same position. The unique constraint on (set_id, position) is
// deferred to the end of the transaction, which is what lets those moments
// exist.
func writeEntryOrder(ctx context.Context, tx pgx.Tx, setId string, order []string) error {
	const query = `UPDATE set_entries SET position = @position WHERE id = @id AND set_id = @set_id`

	for position, id := range order {
		if _, err := tx.Exec(ctx, query, pgx.NamedArgs{
			"position": position,
			"id":       id,
			"set_id":   setId,
		}); err != nil {
			return fmt.Errorf("failed to write the running order: %w", err)
		}
	}
	return nil
}

// touchSet says the set changed now. The running order is what everybody the
// set is shared with plays from, so a change to it is a change for all of them
// and belongs in the window their next sync asks about.
func touchSet(ctx context.Context, tx pgx.Tx, setId string) error {
	const query = `UPDATE sets SET lastChangedAt = @lastChangedAt WHERE id = @id`

	if _, err := tx.Exec(ctx, query, pgx.NamedArgs{
		"id":            setId,
		"lastChangedAt": time.Now().UTC(),
	}); err != nil {
		return fmt.Errorf("failed to mark the set as changed: %w", err)
	}
	return nil
}

// viewOfEntry is how the caller looks at one entry, which is the view every
// entry starts with when they have never said.
func viewOfEntry(ctx context.Context, tx pgx.Tx, entryId string, user User) (*EntryView, error) {
	const query = `
		SELECT transposition, hidden_parts
		FROM set_entry_views
		WHERE entry_id = @entry_id AND user_subject = @user_subject`

	var (
		transposition int16
		hiddenParts   pgtype.Array[string]
	)
	err := tx.QueryRow(ctx, query, pgx.NamedArgs{
		"entry_id":     entryId,
		"user_subject": user.Subject,
	}).Scan(&transposition, &hiddenParts)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return &EntryView{HiddenParts: []string{}}, nil
	case err != nil:
		return nil, fmt.Errorf("failed to read the view of the entry: %w", err)
	}

	return &EntryView{
		Transposition: int(transposition),
		HiddenParts:   emptyWhenNil(hiddenParts.Elements),
	}, nil
}

// validateEntry checks what the store cannot.
func validateEntry(write WriteEntry) error {
	if write.ScoreId == "" {
		return &ErrInvalidSetEntry{Reason: "the entry has no score"}
	}
	if write.Position < 0 {
		return &ErrInvalidSetEntry{Reason: fmt.Sprintf(
			"the entry is played at position %d, which is before the start of the set", write.Position)}
	}
	if write.Transposition < MinTransposition || write.Transposition > MaxTransposition {
		return &ErrInvalidSetEntry{Reason: fmt.Sprintf(
			"the entry is transposed by %d semitones, which is outside the range %d..%d",
			write.Transposition, MinTransposition, MaxTransposition)}
	}
	return nil
}

func without(order []string, id string) []string {
	kept := make([]string, 0, len(order))
	for _, candidate := range order {
		if candidate != id {
			kept = append(kept, candidate)
		}
	}
	return kept
}

func insertAt(order []string, position int, id string) []string {
	with := make([]string, 0, len(order)+1)
	with = append(with, order[:position]...)
	with = append(with, id)
	return append(with, order[position:]...)
}

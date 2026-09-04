package collection

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

// SaveEntry puts one piece into a collection, or changes what the group does
// with it, and hands the entry back as it now reads.
//
// A collection holds a piece once. An entry naming a score that is already in
// the collection under a different entry is ErrScoreAlreadyInCollection, which
// names the entry it is already in — a client that has just been told a piece
// is in the book wants that page, not a second copy of it. Writing the entry
// the score is already in is not that: it is saying what the group does with a
// piece that is in the collection, which is the whole point of the entry.
//
// The pieces with no score are outside the rule. They are told apart by what is
// written next to them, and two lines of a book nobody has scanned are two
// pieces.
//
// Only the owner of a collection can write its entries: what is in it is the
// collection, and the collection is theirs. It is ErrCollectionNotFound for a
// collection that is not there, ErrNotCollectionOwner for one that is somebody
// else's, ErrUnknownScore for an entry pointing at a score that does not exist,
// and ErrInvalidCollectionEntry for an entry the caller has to fix.
func SaveEntry(
	ctx context.Context,
	db *pgxpool.Conn,
	collectionId string,
	entryId string,
	user User,
	write WriteEntry,
) (*Entry, error) {
	slogctx.Info(ctx, "saving collection entry",
		slog.String("collectionId", collectionId), slog.String("entryId", entryId))

	if err := validateEntry(write); err != nil {
		return nil, err
	}

	tx, err := db.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err := requireOwnedCollection(ctx, tx, collectionId, user); err != nil {
		return nil, err
	}

	// An id that is already an entry of another collection is refused rather
	// than taken over: it would point this collection's entry at what another
	// collection's players said about theirs.
	const ownerOfEntryQuery = `SELECT collection_id FROM collection_entries WHERE id = @entry_id`
	var entryBelongsTo string
	err = tx.QueryRow(ctx, ownerOfEntryQuery, pgx.NamedArgs{"entry_id": entryId}).Scan(&entryBelongsTo)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		entryBelongsTo = ""
	case err != nil:
		return nil, fmt.Errorf("failed to look up the entry: %w", err)
	case entryBelongsTo != collectionId:
		return nil, &ErrInvalidCollectionEntry{Reason: "the entry belongs to another collection"}
	}

	// Asked before the write rather than left to the index, so that the answer
	// can say which entry the piece is already in. The index is still there and
	// is what actually holds the rule; this is what makes being turned down
	// useful.
	if err := requireScoreIsNotInCollectionYet(ctx, tx, collectionId, entryId, write.ScoreId); err != nil {
		return nil, err
	}

	if entryBelongsTo == "" {
		const insertQuery = `
			INSERT INTO collection_entries (id, collection_id, score_id, description, transposition)
			VALUES (@id, @collection_id, @score_id, @description, @transposition)`
		_, err = tx.Exec(ctx, insertQuery, pgx.NamedArgs{
			"id":            entryId,
			"collection_id": collectionId,
			"score_id":      write.ScoreId,
			"description":   write.Description,
			"transposition": write.Transposition,
		})
	} else {
		const updateQuery = `
			UPDATE collection_entries
			SET score_id = @score_id, description = @description, transposition = @transposition
			WHERE id = @id AND collection_id = @collection_id`
		_, err = tx.Exec(ctx, updateQuery, pgx.NamedArgs{
			"id":            entryId,
			"collection_id": collectionId,
			"score_id":      write.ScoreId,
			"description":   write.Description,
			"transposition": write.Transposition,
		})
	}
	if err != nil {
		// Two things can turn this row down. The unique index is the piece
		// already being in the collection, which was asked about above and can
		// still happen if somebody else put it there in the meantime; anything
		// else that points at what is not there is the score, since a score is
		// the only thing an entry points at.
		if storage.IsUniqueViolation(err) {
			return nil, &ErrScoreAlreadyInCollection{ScoreId: valueOr(write.ScoreId, "")}
		}
		if storage.IsForeignKeyViolation(err) {
			return nil, &ErrUnknownScore{ScoreId: valueOr(write.ScoreId, "")}
		}
		return nil, fmt.Errorf("failed to save the entry: %w", err)
	}

	// What is in a collection is what everybody it is shared with reads from,
	// so a change to it is a change to the collection for all of them.
	if err := touchCollection(ctx, tx, collectionId); err != nil {
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
		Transposition: write.Transposition,
		View:          *view,
	}, nil
}

// DeleteEntry takes one piece out of a collection. What every player said about
// how they look at it goes with it: it was about a piece that is no longer in
// the collection.
//
// Only the owner of a collection can take an entry out of it. It is
// ErrCollectionNotFound for a collection that is not there,
// ErrNotCollectionOwner for one that is somebody else's, and
// ErrCollectionEntryNotFound for an entry that is not in the collection that
// was named.
func DeleteEntry(
	ctx context.Context,
	db *pgxpool.Conn,
	collectionId string,
	entryId string,
	user User,
) error {
	slogctx.Info(ctx, "deleting collection entry",
		slog.String("collectionId", collectionId), slog.String("entryId", entryId))

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err := requireOwnedCollection(ctx, tx, collectionId, user); err != nil {
		return err
	}

	tag, err := tx.Exec(ctx,
		`DELETE FROM collection_entries WHERE id = @entry_id AND collection_id = @collection_id`,
		pgx.NamedArgs{"entry_id": entryId, "collection_id": collectionId})
	if err != nil {
		return fmt.Errorf("failed to delete the entry: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrCollectionEntryNotFound
	}

	if err := touchCollection(ctx, tx, collectionId); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the deletion: %w", err)
	}
	return nil
}

// requireOwnedCollection answers whether the caller may change this collection.
//
// A collection that is not there, or has been deleted, is not one to write
// entries of. One that is somebody else's is theirs to fill — but that is only
// worth saying to somebody who can see it at all: telling a stranger that a
// collection is not theirs tells them it exists, so for them it is not there.
func requireOwnedCollection(ctx context.Context, tx pgx.Tx, collectionId string, user User) error {
	const query = `
		SELECT c.owner_subject, (sh.email IS NOT NULL) AS shared
		FROM collections AS c
		LEFT JOIN collection_shares AS sh
			ON sh.collection_id = c.id AND sh.email = @email
		WHERE c.id = @id AND c.deletedAt IS NULL`

	var (
		owner  string
		shared bool
	)
	err := tx.QueryRow(ctx, query, pgx.NamedArgs{"id": collectionId, "email": user.Email}).
		Scan(&owner, &shared)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return ErrCollectionNotFound
	case err != nil:
		return fmt.Errorf("failed to look up the owner of the collection: %w", err)
	case owner == user.Subject:
		return nil
	case shared:
		return ErrNotCollectionOwner
	default:
		return ErrCollectionNotFound
	}
}

// requireScoreIsNotInCollectionYet is the rule that makes a collection a
// collection: a piece is in it once.
//
// The entry being written is left out of the question. Writing the entry a
// score is already in is saying what the group does with a piece the collection
// already holds, which is what an entry is for; only a second entry naming the
// same score is a piece twice.
//
// A piece with no score is not asked about at all: there is nothing to compare.
func requireScoreIsNotInCollectionYet(
	ctx context.Context,
	tx pgx.Tx,
	collectionId string,
	entryId string,
	scoreId *string,
) error {
	if scoreId == nil {
		return nil
	}

	const query = `
		SELECT id FROM collection_entries
		WHERE collection_id = @collection_id AND score_id = @score_id AND id <> @entry_id
		LIMIT 1`

	var alreadyIn string
	err := tx.QueryRow(ctx, query, pgx.NamedArgs{
		"collection_id": collectionId,
		"score_id":      *scoreId,
		"entry_id":      entryId,
	}).Scan(&alreadyIn)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return nil
	case err != nil:
		return fmt.Errorf("failed to look up whether the score is already in the collection: %w", err)
	}

	return &ErrScoreAlreadyInCollection{ScoreId: *scoreId, EntryId: alreadyIn}
}

// touchCollection says the collection changed now. What is in it is what
// everybody it is shared with reads from, so a change to it is a change for all
// of them and belongs in the window their next sync asks about.
func touchCollection(ctx context.Context, tx pgx.Tx, collectionId string) error {
	const query = `UPDATE collections SET lastChangedAt = @lastChangedAt WHERE id = @id`

	if _, err := tx.Exec(ctx, query, pgx.NamedArgs{
		"id":            collectionId,
		"lastChangedAt": time.Now().UTC(),
	}); err != nil {
		return fmt.Errorf("failed to mark the collection as changed: %w", err)
	}
	return nil
}

// viewOfEntry is how the caller looks at one entry, which is the view every
// entry starts with when they have never said.
func viewOfEntry(ctx context.Context, tx pgx.Tx, entryId string, user User) (*EntryView, error) {
	const query = `
		SELECT transposition, hidden_parts, zoom
		FROM collection_entry_views
		WHERE entry_id = @entry_id AND user_subject = @user_subject`

	var (
		transposition int16
		hiddenParts   pgtype.Array[string]
		zoom          float32
	)
	err := tx.QueryRow(ctx, query, pgx.NamedArgs{
		"entry_id":     entryId,
		"user_subject": user.Subject,
	}).Scan(&transposition, &hiddenParts, &zoom)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// As written, every part on screen, at the size it is written at.
		return &EntryView{HiddenParts: []string{}, Zoom: DefaultZoom}, nil
	case err != nil:
		return nil, fmt.Errorf("failed to read the view of the entry: %w", err)
	}

	return &EntryView{
		Transposition: int(transposition),
		HiddenParts:   emptyWhenNil(hiddenParts.Elements),
		Zoom:          float64(zoom),
	}, nil
}

func validateEntry(write WriteEntry) error {
	if write.Transposition < MinTransposition || write.Transposition > MaxTransposition {
		return &ErrInvalidCollectionEntry{Reason: fmt.Sprintf(
			"the entry is transposed by %d semitones, which is outside the range %d..%d",
			write.Transposition, MinTransposition, MaxTransposition)}
	}
	return nil
}

func valueOr[T any](value *T, fallback T) T {
	if value == nil {
		return fallback
	}
	return *value
}

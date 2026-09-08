package collection

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	slogctx "github.com/veqryn/slog-context"
)

// SaveEntryView stores how one player looks at one entry of a collection,
// replacing whatever they had said before, and hands it back as it now reads.
//
// Anyone who can read the collection can write their own view of its entries.
// It says nothing about the collection and changes nothing anybody else sees,
// so it asks no more of a player than reading the collection does — being the
// owner is neither needed nor enough to write somebody else's, and there is no
// way to write a view that is not your own: whose it is comes from the caller
// rather than from what they sent.
//
// A collection the caller cannot read, and an entry that is not in the
// collection named, are both ErrCollectionEntryNotFound. Telling the two apart
// would say more about other people's collections than it should.
func SaveEntryView(
	ctx context.Context,
	db *pgxpool.Conn,
	collectionId string,
	entryId string,
	user User,
	write WriteEntryView,
) (*EntryView, error) {
	slogctx.Info(ctx, "saving the caller's view of a collection entry",
		slog.String("collectionId", collectionId), slog.String("entryId", entryId))

	if err := validateTransposition(write.Transposition, "the view"); err != nil {
		return nil, err
	}
	if err := validateZoom(write.Zoom); err != nil {
		return nil, err
	}

	// Whether the caller may write here is whether they may read the collection
	// the entry is in, which is the same join a read of a collection is made
	// of.
	const readableQuery = `
		SELECT 1
		FROM collection_entries AS e
		JOIN collections AS c ON c.id = e.collection_id
		LEFT JOIN collection_shares AS sh
			ON sh.collection_id = c.id AND sh.email = @email
		WHERE e.id = @entry_id
			AND e.collection_id = @collection_id
			AND c.deletedAt IS NULL
			AND (c.owner_subject = @subject OR sh.email IS NOT NULL)`

	var readable int
	err := db.QueryRow(ctx, readableQuery, pgx.NamedArgs{
		"entry_id":      entryId,
		"collection_id": collectionId,
		"subject":       user.Subject,
		"email":         user.Email,
	}).Scan(&readable)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return nil, ErrCollectionEntryNotFound
	case err != nil:
		return nil, fmt.Errorf("failed to look up the entry: %w", err)
	}

	const upsertQuery = `
		INSERT INTO collection_entry_views
			(entry_id, user_subject, transposition, hidden_parts, zoom, last_changed_at)
		VALUES (@entry_id, @user_subject, @transposition, @hidden_parts, @zoom, @last_changed_at)
		ON CONFLICT (entry_id, user_subject) DO UPDATE SET
			transposition = EXCLUDED.transposition,
			hidden_parts = EXCLUDED.hidden_parts,
			zoom = EXCLUDED.zoom,
			last_changed_at = EXCLUDED.last_changed_at`

	_, err = db.Exec(ctx, upsertQuery, pgx.NamedArgs{
		"entry_id":      entryId,
		"user_subject":  user.Subject,
		"transposition": write.Transposition,
		"hidden_parts":  emptyWhenNil(write.HiddenParts),
		"zoom":          write.Zoom,
		// A view is a change to the collection as far as the player who wrote
		// it is concerned, and this is what says so: the collection is last
		// changed for them at the later of its own moment and this one, which
		// is how a view written here reaches their other devices without
		// turning up in anybody else's window.
		"last_changed_at": time.Now().UTC(),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to save the view: %w", err)
	}

	return &EntryView{
		Transposition: write.Transposition,
		HiddenParts:   emptyWhenNil(write.HiddenParts),
		Zoom:          write.Zoom,
	}, nil
}

func validateZoom(zoom float64) error {
	if zoom < MinZoom || zoom > MaxZoom {
		return &ErrInvalidCollection{Reason: fmt.Sprintf(
			"the score is drawn at %g times its size, which is outside the range %g..%g",
			zoom, MinZoom, MaxZoom)}
	}
	return nil
}

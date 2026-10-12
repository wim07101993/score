package set

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

// Save creates or replaces what a set is: its title, what it is about, and who
// may read it. What is played in it is not touched — that is SaveEntry and
// DeleteEntry, one entry at a time.
//
// A set that is not there yet belongs to whoever writes it; one that is can
// only be written by its owner, which is ErrNotSetOwner.
//
// It is one transaction: a set and the addresses it is readable by are written
// together, and half of a replacement is not a set anybody asked for.
func Save(ctx context.Context, db *pgxpool.Conn, setId string, user User, write WriteSet) error {
	slogctx.Info(ctx, "saving set", slog.String("setId", setId))

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const ownerQuery = `
		SELECT owner_subject FROM sets WHERE id = @id
		UNION ALL
		SELECT owner_subject FROM deleted_sets WHERE id = @id
		LIMIT 1`
	var owner string
	err = tx.QueryRow(ctx, ownerQuery, pgx.NamedArgs{"id": setId}).Scan(&owner)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// A set that is not there yet belongs to whoever is creating it.
		owner = user.Subject
	case err != nil:
		return fmt.Errorf("failed to look up the owner of the set: %w", err)
	case owner != user.Subject:
		return ErrNotSetOwner
	}

	const upsertSetQuery = `
		INSERT INTO sets (id, owner_subject, title, description, lastChangedAt)
		VALUES (@id, @owner_subject, @title, @description, @lastChangedAt)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			lastChangedAt = EXCLUDED.lastChangedAt`

	now := time.Now().UTC()
	_, err = tx.Exec(ctx, upsertSetQuery, pgx.NamedArgs{
		"id":            setId,
		"owner_subject": owner,
		"title":         write.Title,
		"description":   write.Description,
		"lastChangedAt": now,
	})
	if err != nil {
		return fmt.Errorf("failed to save the set: %w", err)
	}

	// Writing a set that had been deleted brings it back, with nothing in it.
	_, err = tx.Exec(ctx, `DELETE FROM deleted_sets WHERE id = @id`, pgx.NamedArgs{"id": setId})
	if err != nil {
		return fmt.Errorf("failed to bring the set back: %w", err)
	}

	// The entries are left exactly as they are. What is played is a resource of
	// its own — one entry at a time, at /sets/{setId}/entries/{entryId} — so
	// correcting a title is correcting a title, and a client that has not
	// looked at the running order in a while cannot undo it by saying nothing
	// about it.

	shares := normalizedShares(write.SharedWith, user.Email)
	if err := rememberUnshares(ctx, tx, setId, shares, now); err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `DELETE FROM set_shares WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": setId})
	if err != nil {
		return fmt.Errorf("failed to clear the shares of the set: %w", err)
	}
	for _, email := range shares {
		_, err = tx.Exec(ctx,
			`INSERT INTO set_shares (set_id, email) VALUES (@set_id, @email) ON CONFLICT DO NOTHING`,
			pgx.NamedArgs{"set_id": setId, "email": email})
		if err != nil {
			return fmt.Errorf("failed to share the set: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the set: %w", err)
	}
	return nil
}

// rememberUnshares writes down who is being taken off the set, so that the
// listing can tell them it is gone, and forgets that about whoever is being put
// back on. It has to run before the shares are replaced: who is being taken off
// is whoever is on it now and not in what it is being replaced with.
//
// Putting somebody back on forgets the note, so there is never an old one left
// when they are taken off again; should one be there all the same, the later
// moment is the one kept, since that is the one their devices have not heard
// about yet.
func rememberUnshares(ctx context.Context, tx pgx.Tx, setId string, shares []string, now time.Time) error {
	const unsharedQuery = `
		INSERT INTO set_unshares (set_id, email, unshared_at)
		SELECT set_id, email, @now
		FROM set_shares
		WHERE set_id = @set_id AND NOT (email = ANY(@shares))
		ON CONFLICT (set_id, email) DO UPDATE SET unshared_at = EXCLUDED.unshared_at`

	_, err := tx.Exec(ctx, unsharedQuery, pgx.NamedArgs{"set_id": setId, "shares": shares, "now": now})
	if err != nil {
		return fmt.Errorf("failed to remember who the set is no longer shared with: %w", err)
	}

	_, err = tx.Exec(ctx,
		`DELETE FROM set_unshares WHERE set_id = @set_id AND email = ANY(@shares)`,
		pgx.NamedArgs{"set_id": setId, "shares": shares})
	if err != nil {
		return fmt.Errorf("failed to forget that the set was no longer shared: %w", err)
	}
	return nil
}

// validateTransposition holds both halves of a transposition to the range the
// player offers: the entry's, which is where the band plays a song, and the
// view's, which is how far one player reads it from there.
func validateTransposition(semitones int, what string) error {
	if semitones < MinTransposition || semitones > MaxTransposition {
		return &ErrInvalidSet{Reason: fmt.Sprintf(
			"%s is transposed by %d semitones, which is outside the range %d..%d",
			what, semitones, MinTransposition, MaxTransposition)}
	}
	return nil
}

// normalizedShares tidies the addresses a set is shared with: they are lowered
// so that looking one up is a plain comparison, blanks are dropped, and the
// owner is not shared with, since they already have it.
func normalizedShares(emails []string, ownerEmail string) []string {
	seen := make(map[string]struct{}, len(emails))
	shares := make([]string, 0, len(emails))

	for _, email := range emails {
		normalized := NormalizeEmail(email)
		if normalized == "" || normalized == ownerEmail {
			continue
		}
		if _, duplicate := seen[normalized]; duplicate {
			continue
		}
		seen[normalized] = struct{}{}
		shares = append(shares, normalized)
	}
	return shares
}

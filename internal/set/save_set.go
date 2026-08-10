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

	const ownerQuery = `SELECT owner_subject FROM sets WHERE id = @id`
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
		INSERT INTO sets (id, owner_subject, title, description, lastChangedAt, deletedAt)
		VALUES (@id, @owner_subject, @title, @description, @lastChangedAt, NULL)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			lastChangedAt = EXCLUDED.lastChangedAt,
			-- Writing a set again brings it back: a client that still has it
			-- and edits it is saying it should exist.
			deletedAt = NULL`

	_, err = tx.Exec(ctx, upsertSetQuery, pgx.NamedArgs{
		"id":            setId,
		"owner_subject": owner,
		"title":         write.Title,
		"description":   write.Description,
		"lastChangedAt": time.Now().UTC(),
	})
	if err != nil {
		return fmt.Errorf("failed to save the set: %w", err)
	}

	// The entries are left exactly as they are. What is played is a resource of
	// its own — one entry at a time, at /sets/{setId}/entries/{entryId} — so
	// correcting a title is correcting a title, and a client that has not
	// looked at the running order in a while cannot undo it by saying nothing
	// about it.

	_, err = tx.Exec(ctx, `DELETE FROM set_shares WHERE set_id = @set_id`, pgx.NamedArgs{"set_id": setId})
	if err != nil {
		return fmt.Errorf("failed to clear the shares of the set: %w", err)
	}
	for _, email := range normalizedShares(write.SharedWith, user.Email) {
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

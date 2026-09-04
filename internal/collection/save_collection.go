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

// Save creates or replaces what a collection is: its title, what it is about,
// and who may read it. What is in it is not touched — that is SaveEntry and
// DeleteEntry, one entry at a time.
//
// A collection that is not there yet belongs to whoever writes it; one that is
// can only be written by its owner, which is ErrNotCollectionOwner.
//
// It is one transaction: a collection and the addresses it is readable by are
// written together, and half of a replacement is not a collection anybody asked
// for.
func Save(
	ctx context.Context,
	db *pgxpool.Conn,
	collectionId string,
	user User,
	write WriteCollection,
) error {
	slogctx.Info(ctx, "saving collection", slog.String("collectionId", collectionId))

	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const ownerQuery = `SELECT owner_subject FROM collections WHERE id = @id`
	var owner string
	err = tx.QueryRow(ctx, ownerQuery, pgx.NamedArgs{"id": collectionId}).Scan(&owner)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// A collection that is not there yet belongs to whoever is creating it.
		owner = user.Subject
	case err != nil:
		return fmt.Errorf("failed to look up the owner of the collection: %w", err)
	case owner != user.Subject:
		return ErrNotCollectionOwner
	}

	const upsertQuery = `
		INSERT INTO collections (id, owner_subject, title, description, lastChangedAt, deletedAt)
		VALUES (@id, @owner_subject, @title, @description, @lastChangedAt, NULL)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			lastChangedAt = EXCLUDED.lastChangedAt,
			-- Writing a collection again brings it back: a client that still
			-- has it and edits it is saying it should exist.
			deletedAt = NULL`

	_, err = tx.Exec(ctx, upsertQuery, pgx.NamedArgs{
		"id":            collectionId,
		"owner_subject": owner,
		"title":         write.Title,
		"description":   write.Description,
		"lastChangedAt": time.Now().UTC(),
	})
	if err != nil {
		return fmt.Errorf("failed to save the collection: %w", err)
	}

	// The entries are left exactly as they are. What is in the collection is a
	// resource of its own — one entry at a time, at
	// /collections/{collectionId}/entries/{entryId} — so correcting a title is
	// correcting a title, and a client that has not looked at the collection in
	// a while cannot empty it by saying nothing about it.

	_, err = tx.Exec(ctx,
		`DELETE FROM collection_shares WHERE collection_id = @collection_id`,
		pgx.NamedArgs{"collection_id": collectionId})
	if err != nil {
		return fmt.Errorf("failed to clear the shares of the collection: %w", err)
	}
	for _, email := range normalizedShares(write.SharedWith, user.Email) {
		_, err = tx.Exec(ctx,
			`INSERT INTO collection_shares (collection_id, email)
				VALUES (@collection_id, @email) ON CONFLICT DO NOTHING`,
			pgx.NamedArgs{"collection_id": collectionId, "email": email})
		if err != nil {
			return fmt.Errorf("failed to share the collection: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit the collection: %w", err)
	}
	return nil
}

// validateTransposition holds both halves of a transposition to the range the
// player offers: the entry's, which is where the group plays a piece, and the
// view's, which is how far one player reads it from there.
func validateTransposition(semitones int, what string) error {
	if semitones < MinTransposition || semitones > MaxTransposition {
		return &ErrInvalidCollection{Reason: fmt.Sprintf(
			"%s is transposed by %d semitones, which is outside the range %d..%d",
			what, semitones, MinTransposition, MaxTransposition)}
	}
	return nil
}

// normalizedShares tidies the addresses a collection is shared with: they are
// lowered so that looking one up is a plain comparison, blanks are dropped, and
// the owner is not shared with, since they already have it.
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

package collection

import (
	"context"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// User is who is asking after a collection. A collection belongs to someone by
// subject and is shared with them by address, so telling what someone may see
// takes both.
//
// It is this package's own idea of a caller rather than the one the auth layer
// hands around, so that nothing down here has to know how somebody proved who
// they are. Build one with NewUser rather than by hand: the address has to be
// in the form shares are compared in, and NewUser is what puts it there.
type User struct {
	Subject string
	Email   string
}

func NewUser(subject, email string) User {
	return User{Subject: subject, Email: NormalizeEmail(email)}
}

func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// selectCollections is the head of both the lookup of one collection and the
// listing of a window of them: they select the same columns, in the order
// scanCollections reads them, and differ only in what they filter by.
//
// The join on shares is what makes one readable: a row survives it when the
// caller owns the collection or their address is on it, which the clauses below
// ask as `shared`.
//
// A collection is last changed at the later of two moments, and which two
// depends on who is asking. One is when the collection itself was written,
// which is the same for everybody. The other is when the caller last said
// something about how they look at one of its entries, which is theirs alone. A
// sync asks for everything that changed for the caller since it last asked, and
// a view they wrote on another device is exactly that — while somebody else
// writing theirs is not, and does not turn up here.
const selectCollections = `
	SELECT id, owner_subject, title, description, last_changed_at, deletedAt
	FROM (
		SELECT c.id, c.owner_subject, c.title, c.description, c.deletedAt,
		       (sh.email IS NOT NULL) AS shared,
		       GREATEST(c.lastChangedAt, COALESCE(v.last_changed_at, c.lastChangedAt)) AS last_changed_at
		FROM collections AS c
		LEFT JOIN collection_shares AS sh ON sh.collection_id = c.id AND sh.email = @email
		LEFT JOIN LATERAL (
			SELECT max(ev.last_changed_at) AS last_changed_at
			FROM collection_entry_views AS ev
			JOIN collection_entries AS e ON e.id = ev.entry_id
			WHERE e.collection_id = c.id AND ev.user_subject = @subject
		) AS v ON TRUE
	) AS collections_for_caller`

func scanCollections(rows pgx.Rows, user User) ([]*Collection, error) {
	defer rows.Close()

	collections := make([]*Collection, 0)
	for rows.Next() {
		var (
			id            string
			ownerSubject  string
			title         string
			description   string
			lastChangedAt time.Time
			deletedAt     *time.Time
		)
		if err := rows.Scan(&id, &ownerSubject, &title, &description, &lastChangedAt, &deletedAt); err != nil {
			return nil, err
		}

		// The store hands a moment back in whatever zone the process runs in.
		// Which one that is says nothing about the collection, and letting it
		// through would have the same collection read differently from one
		// deployment to the next, so it is said in UTC and the instant is what
		// is left.
		lastChangedAt = lastChangedAt.UTC()
		if deletedAt != nil {
			utc := deletedAt.UTC()
			deletedAt = &utc
		}

		collections = append(collections, &Collection{
			Id:            id,
			Title:         title,
			Description:   description,
			Entries:       make([]Entry, 0),
			SharedWith:    make([]string, 0),
			IsOwner:       ownerSubject == user.Subject,
			LastChangedAt: lastChangedAt,
			DeletedAt:     deletedAt,
		})
	}
	return collections, rows.Err()
}

// fillIn reads the entries and shares of the given collections. It is one query
// for all of them rather than one per collection, so that listing a window
// costs the same three round trips however many collections are in it.
func fillIn(ctx context.Context, db *pgxpool.Conn, collections []*Collection, user User) error {
	if len(collections) == 0 {
		return nil
	}

	byId := make(map[string]*Collection, len(collections))
	ids := make([]string, 0, len(collections))
	for _, c := range collections {
		byId[c.Id] = c
		ids = append(ids, c.Id)
	}

	// The join on views is what makes a view the caller's own: it matches on
	// the subject of whoever is asking, so a player is handed what they said
	// and nothing about what anybody else said. An entry nobody has looked at
	// differently has no row at all, and the coalesced defaults are the view
	// every entry starts with — as written, every part on screen.
	//
	// The join on scores is only there to sort by. A collection has no order of
	// its own, and handing one back in whatever order the rows came off the
	// disk would be a different list every time it was read; by title is the
	// order somebody looking for a piece in a book reads in. A piece with no
	// score is filed under what is written next to it, which is the only name
	// it has. The id breaks the tie, so that two pieces of the same name always
	// come back the same way round.
	const entriesQuery = `
		SELECT e.collection_id, e.id, e.score_id, e.description, e.transposition,
		       COALESCE(v.transposition, 0), COALESCE(v.hidden_parts, '{}'), COALESCE(v.zoom, 1)
		FROM collection_entries AS e
		LEFT JOIN collection_entry_views AS v
			ON v.entry_id = e.id AND v.user_subject = @subject
		LEFT JOIN scores AS s ON s.id = e.score_id
		WHERE e.collection_id = ANY(@ids)
		ORDER BY e.collection_id,
		         lower(COALESCE(NULLIF(s.work_title, ''), NULLIF(s.movement_title, ''), e.description)),
		         e.id`

	rows, err := db.Query(ctx, entriesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
	if err != nil {
		return err
	}
	for rows.Next() {
		var (
			collectionId      string
			entry             Entry
			transposition     int16
			viewTransposition int16
			hiddenParts       pgtype.Array[string]
			zoom              float32
		)
		if err := rows.Scan(&collectionId, &entry.Id, &entry.ScoreId, &entry.Description,
			&transposition, &viewTransposition, &hiddenParts, &zoom); err != nil {
			rows.Close()
			return err
		}
		entry.Transposition = int(transposition)
		entry.View = EntryView{
			Transposition: int(viewTransposition),
			HiddenParts:   emptyWhenNil(hiddenParts.Elements),
			Zoom:          float64(zoom),
		}

		if c := byId[collectionId]; c != nil {
			c.Entries = append(c.Entries, entry)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}

	// Who else a collection is shared with is only the owner's business, which
	// is what the join on owner_subject says: for a collection that is merely
	// shared with the caller, no row comes back and SharedWith stays empty.
	const sharesQuery = `
		SELECT sh.collection_id, sh.email
		FROM collection_shares AS sh
		JOIN collections AS c ON c.id = sh.collection_id
		WHERE sh.collection_id = ANY(@ids) AND c.owner_subject = @subject
		ORDER BY sh.email`

	shareRows, err := db.Query(ctx, sharesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
	if err != nil {
		return err
	}
	defer shareRows.Close()
	for shareRows.Next() {
		var collectionId, email string
		if err := shareRows.Scan(&collectionId, &email); err != nil {
			return err
		}
		if c := byId[collectionId]; c != nil {
			c.SharedWith = append(c.SharedWith, email)
		}
	}
	return shareRows.Err()
}

// emptyWhenNil keeps an absent list an empty list rather than a null, so that a
// client never has to tell the two apart.
func emptyWhenNil(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}

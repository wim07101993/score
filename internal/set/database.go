package set

import (
	"context"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// User is who is asking after a set. A set belongs to someone by subject and is
// shared with them by address, so telling what someone may see takes both.
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

// selectSets is the head of both the lookup of one set and the listing of a
// window of them: they select the same columns, in the order scanSets reads
// them, and differ only in what they filter by.
//
// The join on shares is what makes one readable: a row survives it when the
// caller owns the set or their address is on it, which the clauses below ask
// as `shared`.
//
// A set is last changed at the later of two moments, and which two depends on
// who is asking. One is when the set itself was written, which is the same for
// everybody. The other is when the caller last said something about how they
// look at one of its entries, which is theirs alone. A sync asks for
// everything that changed for the caller since it last asked, and a view they
// wrote on another device is exactly that — while somebody else writing theirs
// is not, and does not turn up here.
const selectSets = `
	SELECT id, owner_subject, title, description, last_changed_at, deletedAt
	FROM (
		SELECT s.id, s.owner_subject, s.title, s.description, s.deletedAt,
		       (sh.email IS NOT NULL) AS shared,
		       GREATEST(s.lastChangedAt, COALESCE(v.last_changed_at, s.lastChangedAt)) AS last_changed_at
		FROM sets AS s
		LEFT JOIN set_shares AS sh ON sh.set_id = s.id AND sh.email = @email
		LEFT JOIN LATERAL (
			SELECT max(ev.last_changed_at) AS last_changed_at
			FROM set_entry_views AS ev
			JOIN set_entries AS e ON e.id = ev.entry_id
			WHERE e.set_id = s.id AND ev.user_subject = @subject
		) AS v ON TRUE
	) AS sets_for_caller`

func scanSets(rows pgx.Rows, user User) ([]*Set, error) {
	defer rows.Close()

	sets := make([]*Set, 0)
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
		// Which one that is says nothing about the set, and letting it through
		// would have the same set read differently from one deployment to the
		// next, so it is said in UTC and the instant is what is left.
		lastChangedAt = lastChangedAt.UTC()
		if deletedAt != nil {
			utc := deletedAt.UTC()
			deletedAt = &utc
		}

		sets = append(sets, &Set{
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
	return sets, rows.Err()
}

// fillIn reads the entries and shares of the given sets. It is one query for
// all of them rather than one per set, so that listing a window costs the same
// three round trips however many sets are in it.
func fillIn(ctx context.Context, db *pgxpool.Conn, sets []*Set, user User) error {
	if len(sets) == 0 {
		return nil
	}

	byId := make(map[string]*Set, len(sets))
	ids := make([]string, 0, len(sets))
	for _, s := range sets {
		byId[s.Id] = s
		ids = append(ids, s.Id)
	}

	// The join is what makes a view the caller's own: it matches on the subject
	// of whoever is asking, so a player is handed what they said and nothing
	// about what anybody else said. An entry nobody has looked at differently
	// has no row at all, and the coalesced defaults are the view every entry
	// starts with — as written, every part on screen.
	const entriesQuery = `
		SELECT e.set_id, e.id, e.score_id, e.description, e.position, e.transposition,
		       COALESCE(v.transposition, 0), COALESCE(v.hidden_parts, '{}'), COALESCE(v.zoom, 1)
		FROM set_entries AS e
		LEFT JOIN set_entry_views AS v ON v.entry_id = e.id AND v.user_subject = @subject
		WHERE e.set_id = ANY(@ids)
		ORDER BY e.set_id, e.position`

	rows, err := db.Query(ctx, entriesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
	if err != nil {
		return err
	}
	for rows.Next() {
		var (
			setId             string
			entry             Entry
			position          int32
			transposition     int16
			viewTransposition int16
			hiddenParts       pgtype.Array[string]
			zoom              float32
		)
		if err := rows.Scan(&setId, &entry.Id, &entry.ScoreId, &entry.Description, &position,
			&transposition, &viewTransposition, &hiddenParts, &zoom); err != nil {
			rows.Close()
			return err
		}
		entry.Position = int(position)
		entry.Transposition = int(transposition)
		entry.View = EntryView{
			Transposition: int(viewTransposition),
			HiddenParts:   emptyWhenNil(hiddenParts.Elements),
			Zoom:          float64(zoom),
		}

		if s := byId[setId]; s != nil {
			s.Entries = append(s.Entries, entry)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}

	// Who else a set is shared with is only the owner's business, which is what
	// the join on owner_subject says: for a set that is merely shared with the
	// caller, no row comes back and SharedWith stays empty.
	const sharesQuery = `
		SELECT sh.set_id, sh.email
		FROM set_shares AS sh
		JOIN sets AS s ON s.id = sh.set_id
		WHERE sh.set_id = ANY(@ids) AND s.owner_subject = @subject
		ORDER BY sh.email`

	shareRows, err := db.Query(ctx, sharesQuery, pgx.NamedArgs{"ids": ids, "subject": user.Subject})
	if err != nil {
		return err
	}
	defer shareRows.Close()
	for shareRows.Next() {
		var setId, email string
		if err := shareRows.Scan(&setId, &email); err != nil {
			return err
		}
		if s := byId[setId]; s != nil {
			s.SharedWith = append(s.SharedWith, email)
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

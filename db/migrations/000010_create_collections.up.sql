-- A collection is the other way a player groups the music they have.
--
-- A set is a gig: the same song may come round twice, and the order is what is
-- played. A collection is a book, or the repertoire of the band a player is in
-- — the pieces belong together, but nothing says which comes first, and a piece
-- is either in it or it is not. So the two are separate things rather than one
-- thing with a switch on it: there is no position to keep here, and there is a
-- rule about the same score twice that a set must not have.
--
-- Everything else they share, because it is the same music being looked at by
-- the same people: a collection is shared by address, its entries carry the key
-- the group plays a piece in, and every player has their own view of every
-- entry. A piece read a fourth up off a tablet at arm's length is read that way
-- whether it was opened out of a gig or out of a book.
CREATE TABLE IF NOT EXISTS collections
(
    id            UUID PRIMARY KEY,
    owner_subject TEXT        NOT NULL,
    title         TEXT        NOT NULL DEFAULT '',
    description   TEXT        NOT NULL DEFAULT '',
    lastChangedAt TIMESTAMPTZ NOT NULL,
    deletedAt     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS collections_owner_subject_idx ON collections (owner_subject);
CREATE INDEX IF NOT EXISTS collections_lastchangedat_idx ON collections (lastChangedAt);

CREATE TABLE IF NOT EXISTS collection_entries
(
    id            UUID PRIMARY KEY,
    collection_id UUID     NOT NULL REFERENCES collections (id) ON DELETE CASCADE,
    -- Null for a piece that is in the book but not in here. A collection of
    -- what has been uploaded is not the collection: half of what is in a book
    -- is on paper until somebody gets round to scanning it, and leaving those
    -- pieces out would mean the book cannot be written down until it has all
    -- been. Such an entry is called by its description.
    score_id      UUID     REFERENCES scores (id),
    description   TEXT     NOT NULL DEFAULT '',
    transposition SMALLINT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS collection_entries_collection_id_idx
    ON collection_entries (collection_id);

-- A score is in a collection or it is not; it cannot be in one twice. That is
-- the whole difference between a collection and a set, and it is said here as
-- well as in the server so that a row that got in some other way is still a
-- collection somebody could have written.
--
-- The pieces that have no score are outside the rule rather than all one and
-- the same: they are told apart by what is written next to them, and two lines
-- of a book that have yet to be scanned are two pieces. A partial index is what
-- says that — in SQL, one null is not equal to another, so a plain unique
-- constraint would allow them anyway; being explicit is being readable.
CREATE UNIQUE INDEX IF NOT EXISTS collection_entries_one_score_once_idx
    ON collection_entries (collection_id, score_id)
    WHERE score_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS collection_entry_views
(
    entry_id        UUID        NOT NULL REFERENCES collection_entries (id) ON DELETE CASCADE,
    user_subject    TEXT        NOT NULL,
    -- On top of the entry's own transposition rather than instead of it: the
    -- entry says the group plays this one a tone down, this says the player
    -- reads that a fifth up.
    transposition   SMALLINT    NOT NULL DEFAULT 0,
    hidden_parts    TEXT[]      NOT NULL DEFAULT '{}',
    zoom            REAL        NOT NULL DEFAULT 1,
    last_changed_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (entry_id, user_subject),
    CONSTRAINT collection_entry_views_zoom_check CHECK (zoom >= 0.5 AND zoom <= 4)
);

CREATE INDEX IF NOT EXISTS collection_entry_views_user_subject_idx
    ON collection_entry_views (user_subject);

CREATE TABLE IF NOT EXISTS collection_shares
(
    collection_id UUID NOT NULL REFERENCES collections (id) ON DELETE CASCADE,
    email         TEXT NOT NULL,
    PRIMARY KEY (collection_id, email)
);

CREATE INDEX IF NOT EXISTS collection_shares_email_idx ON collection_shares (email);

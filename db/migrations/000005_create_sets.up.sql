CREATE TABLE IF NOT EXISTS sets
(
    id            UUID PRIMARY KEY,
    owner_subject TEXT      NOT NULL,
    title         TEXT      NOT NULL DEFAULT '',
    description   TEXT      NOT NULL DEFAULT '',
    lastChangedAt TIMESTAMP NOT NULL,
    deletedAt     TIMESTAMP
);

CREATE INDEX IF NOT EXISTS sets_owner_subject_idx ON sets (owner_subject);
CREATE INDEX IF NOT EXISTS sets_lastchangedat_idx ON sets (lastChangedAt);

CREATE TABLE IF NOT EXISTS set_entries
(
    id            UUID PRIMARY KEY,
    set_id        UUID     NOT NULL REFERENCES sets (id) ON DELETE CASCADE,
    position      INT      NOT NULL,
    score_id      UUID     NOT NULL REFERENCES scores (id),
    description   TEXT     NOT NULL DEFAULT '',
    transposition SMALLINT NOT NULL DEFAULT 0,
    hidden_parts  TEXT[]   NOT NULL DEFAULT '{}',
    UNIQUE (set_id, position)
);

CREATE INDEX IF NOT EXISTS set_entries_set_id_idx ON set_entries (set_id);

CREATE TABLE IF NOT EXISTS set_shares
(
    set_id UUID NOT NULL REFERENCES sets (id) ON DELETE CASCADE,
    email  TEXT NOT NULL,
    PRIMARY KEY (set_id, email)
);

CREATE INDEX IF NOT EXISTS set_shares_email_idx ON set_shares (email);

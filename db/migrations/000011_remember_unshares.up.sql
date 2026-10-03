-- Taking somebody off a set or a collection has to reach them.
--
-- A client learns what changed by asking for everything that changed for it
-- since it last asked, and a set that is deleted is still answered, marked as
-- deleted, so that a device holding a copy drops it rather than keeping it
-- forever. Taking an address off a set did nothing of the kind: the share was
-- simply gone, the set stopped turning up for that address, and a device that
-- had it went on holding it as it was, every view written on it refused, with
-- nothing ever telling it why.
--
-- So when an address is taken off, that is written down, with when it was
-- done. The listing for that address answers the set as gone from that moment
-- on — exactly the way it answers a set that was deleted — and nothing more
-- about it: what happens to the set afterwards is no longer the business of
-- somebody it is not shared with.
--
-- Sharing with the address again takes the note away, since the set is theirs
-- to read once more; deleting the set for good takes it along with the set.
CREATE TABLE IF NOT EXISTS set_unshares
(
    set_id      UUID        NOT NULL REFERENCES sets (id) ON DELETE CASCADE,
    email       TEXT        NOT NULL,
    unshared_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (set_id, email)
);

CREATE INDEX IF NOT EXISTS set_unshares_email_idx ON set_unshares (email);

CREATE TABLE IF NOT EXISTS collection_unshares
(
    collection_id UUID        NOT NULL REFERENCES collections (id) ON DELETE CASCADE,
    email         TEXT        NOT NULL,
    unshared_at   TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (collection_id, email)
);

CREATE INDEX IF NOT EXISTS collection_unshares_email_idx ON collection_unshares (email);

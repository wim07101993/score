-- A deleted set or collection is moved out of its table into one of its own,
-- keeping nothing but its id, its owner, who it was shared with and when it was
-- deleted: enough for the change window to tell all of them that it is gone.

CREATE TABLE IF NOT EXISTS deleted_sets
(
    id            UUID PRIMARY KEY,
    owner_subject TEXT        NOT NULL,
    shared_with   TEXT[]      NOT NULL DEFAULT '{}',
    deleted_at    TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS deleted_sets_owner_subject_idx ON deleted_sets (owner_subject);
CREATE INDEX IF NOT EXISTS deleted_sets_shared_with_idx ON deleted_sets USING GIN (shared_with);
CREATE INDEX IF NOT EXISTS deleted_sets_deleted_at_idx ON deleted_sets (deleted_at);

CREATE TABLE IF NOT EXISTS deleted_collections
(
    id            UUID PRIMARY KEY,
    owner_subject TEXT        NOT NULL,
    shared_with   TEXT[]      NOT NULL DEFAULT '{}',
    deleted_at    TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS deleted_collections_owner_subject_idx ON deleted_collections (owner_subject);
CREATE INDEX IF NOT EXISTS deleted_collections_shared_with_idx ON deleted_collections USING GIN (shared_with);
CREATE INDEX IF NOT EXISTS deleted_collections_deleted_at_idx ON deleted_collections (deleted_at);

INSERT INTO deleted_sets (id, owner_subject, shared_with, deleted_at)
SELECT s.id,
       s.owner_subject,
       ARRAY(SELECT email FROM set_shares WHERE set_id = s.id
             UNION
             SELECT email FROM set_unshares WHERE set_id = s.id),
       s.deletedAt
FROM sets AS s
WHERE s.deletedAt IS NOT NULL;

DELETE FROM sets
WHERE deletedAt IS NOT NULL;

ALTER TABLE sets
    DROP COLUMN IF EXISTS deletedAt;

INSERT INTO deleted_collections (id, owner_subject, shared_with, deleted_at)
SELECT c.id,
       c.owner_subject,
       ARRAY(SELECT email FROM collection_shares WHERE collection_id = c.id
             UNION
             SELECT email FROM collection_unshares WHERE collection_id = c.id),
       c.deletedAt
FROM collections AS c
WHERE c.deletedAt IS NOT NULL;

DELETE FROM collections
WHERE deletedAt IS NOT NULL;

ALTER TABLE collections
    DROP COLUMN IF EXISTS deletedAt;

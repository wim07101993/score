-- Going back puts a deleted set or collection back in its table, marked as
-- deleted the way it was before, with nothing in it and shared with nobody.

ALTER TABLE sets
    ADD COLUMN IF NOT EXISTS deletedAt TIMESTAMPTZ;

INSERT INTO sets (id, owner_subject, title, description, lastChangedAt, deletedAt)
SELECT id, owner_subject, '', '', deleted_at, deleted_at
FROM deleted_sets
ON CONFLICT (id) DO NOTHING;

ALTER TABLE collections
    ADD COLUMN IF NOT EXISTS deletedAt TIMESTAMPTZ;

INSERT INTO collections (id, owner_subject, title, description, lastChangedAt, deletedAt)
SELECT id, owner_subject, '', '', deleted_at, deleted_at
FROM deleted_collections
ON CONFLICT (id) DO NOTHING;

DROP TABLE IF EXISTS deleted_collections;
DROP TABLE IF EXISTS deleted_sets;

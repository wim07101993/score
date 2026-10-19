-- A collection holds scores and nothing else.
--
-- A piece that has not been scanned has nothing to open, so a collection has
-- nothing to do with it. The pieces already written down without one are
-- dropped, and the collections they were in are marked as changed so that every
-- device they are shared with hears about it at its next sync.
UPDATE collections
SET lastChangedAt = now()
WHERE id IN (SELECT collection_id FROM collection_entries WHERE score_id IS NULL);

DELETE
FROM collection_entries
WHERE score_id IS NULL;

ALTER TABLE collection_entries
    ALTER COLUMN score_id SET NOT NULL;

-- With every entry naming a score, a score being in a collection once is a plain
-- unique index rather than a partial one.
DROP INDEX IF EXISTS collection_entries_one_score_once_idx;
CREATE UNIQUE INDEX IF NOT EXISTS collection_entries_one_score_once_idx
    ON collection_entries (collection_id, score_id);

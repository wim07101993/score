-- Going back allows an entry without a score again. The entries that were
-- dropped going up do not come back: nothing was kept of them.
DROP INDEX IF EXISTS collection_entries_one_score_once_idx;
CREATE UNIQUE INDEX IF NOT EXISTS collection_entries_one_score_once_idx
    ON collection_entries (collection_id, score_id)
    WHERE score_id IS NOT NULL;

ALTER TABLE collection_entries
    ALTER COLUMN score_id DROP NOT NULL;

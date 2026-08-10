-- Back to one answer per entry for everybody. What every player but the owner
-- said about how they look at a score cannot come along: there is nowhere on an
-- entry to put it.
ALTER TABLE set_entries
    ADD COLUMN IF NOT EXISTS hidden_parts TEXT[] NOT NULL DEFAULT '{}';

UPDATE set_entries AS e
SET hidden_parts = v.hidden_parts
FROM set_entry_views AS v,
     sets AS s
WHERE v.entry_id = e.id
  AND s.id = e.set_id
  AND s.owner_subject = v.user_subject;

DROP TABLE IF EXISTS set_entry_views;

ALTER TABLE set_entries
    DROP CONSTRAINT IF EXISTS set_entries_set_id_position_key;
ALTER TABLE set_entries
    ADD CONSTRAINT set_entries_set_id_position_key UNIQUE (set_id, position);

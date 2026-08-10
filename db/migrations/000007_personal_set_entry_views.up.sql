-- How a score is looked at moves off the entry and onto the player.
--
-- A set says what the band plays; how one player reads it is their own. The
-- saxophone player transposing their part and the pianist wanting the piano
-- staff alone on screen are two answers to the same question, and there is no
-- one answer to store on the entry they share.

-- An entry now keeps its id across a write, so that a view goes on pointing at
-- the same entry after the owner has edited the set. That means the positions
-- of the rows that stay are shuffled in place rather than written afresh, and
-- swapping two of them passes through a moment where both hold the same
-- position. Checking at the end of the transaction rather than at every row is
-- what lets that moment exist.
ALTER TABLE set_entries
    DROP CONSTRAINT IF EXISTS set_entries_set_id_position_key;
ALTER TABLE set_entries
    ADD CONSTRAINT set_entries_set_id_position_key
        UNIQUE (set_id, position) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS set_entry_views
(
    entry_id        UUID        NOT NULL REFERENCES set_entries (id) ON DELETE CASCADE,
    user_subject    TEXT        NOT NULL,
    -- On top of the entry's own transposition rather than instead of it: the
    -- entry says the band plays this one a tone down, this says the player
    -- reads that a fifth up.
    transposition   SMALLINT    NOT NULL DEFAULT 0,
    hidden_parts    TEXT[]      NOT NULL DEFAULT '{}',
    last_changed_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (entry_id, user_subject)
);

CREATE INDEX IF NOT EXISTS set_entry_views_user_subject_idx ON set_entry_views (user_subject);

-- What was on the entry was written by whoever owns the set, since they are the
-- only one who could write it. So it becomes their own view rather than being
-- thrown away: they set it, and they should still have it.
INSERT INTO set_entry_views (entry_id, user_subject, transposition, hidden_parts, last_changed_at)
SELECT e.id, s.owner_subject, 0, e.hidden_parts, now()
FROM set_entries AS e
         JOIN sets AS s ON s.id = e.set_id
WHERE COALESCE(array_length(e.hidden_parts, 1), 0) > 0
ON CONFLICT DO NOTHING;

ALTER TABLE set_entries
    DROP COLUMN hidden_parts;

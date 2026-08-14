-- Going back means there is nowhere to keep a song that has no score, so the
-- songs that have none are dropped. The alternative is a migration that cannot
-- run at all on any set that used the feature, which is worse: it would leave
-- the schema stuck at a version nobody can go back from.
--
-- The running order is closed up around them afterwards, since positions are
-- nought upwards with no gaps.
DELETE
FROM set_entries
WHERE score_id IS NULL;

UPDATE set_entries AS e
SET position = renumbered.position
FROM (SELECT id, row_number() OVER (PARTITION BY set_id ORDER BY position) - 1 AS position
      FROM set_entries) AS renumbered
WHERE e.id = renumbered.id
  AND e.position IS DISTINCT FROM renumbered.position;

ALTER TABLE set_entries
    ALTER COLUMN score_id SET NOT NULL;

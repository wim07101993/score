-- A gig has songs in it that this app has never seen.
--
-- Half a set list is music on paper, in a folder, on somebody's stand. Until
-- now the running order could only name a song that had been uploaded, so the
-- rest of the gig had to be remembered somewhere else — which means the running
-- order was not the running order.
--
-- An entry without a score is what the band plays and where in the gig they
-- play it, with nothing to open. What it is called is its description, which is
-- the only thing there is to go by when there is no score to take a title from.
ALTER TABLE set_entries
    ALTER COLUMN score_id DROP NOT NULL;

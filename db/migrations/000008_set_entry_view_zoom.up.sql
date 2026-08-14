-- How big a player draws a score is part of how they look at it.
--
-- It belongs with the key they read it in and the parts they have on screen,
-- for the same reason those do: it is the player's own and nobody else's. The
-- one who reads their part at arm's length on a tablet on a stand and the one
-- holding a phone are two answers to the same question, and there is no one
-- answer to store on the entry they share.
--
-- Every view that exists was written by somebody reading a score at the size it
-- is written at, since there was no way to say otherwise until now, so that is
-- what they all get.
ALTER TABLE set_entry_views
    ADD COLUMN IF NOT EXISTS zoom REAL NOT NULL DEFAULT 1;

-- The range the player offers, said here as well so that a row that got past
-- the server some other way is still a size a score can be drawn at.
ALTER TABLE set_entry_views
    DROP CONSTRAINT IF EXISTS set_entry_views_zoom_check;
ALTER TABLE set_entry_views
    ADD CONSTRAINT set_entry_views_zoom_check CHECK (zoom >= 0.5 AND zoom <= 4);

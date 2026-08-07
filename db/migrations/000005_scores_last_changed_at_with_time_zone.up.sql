-- lastChangedAt held a moment in UTC, by a convention every reader and writer
-- had to keep. A bound written in any other zone was compared as the wall clock
-- it read rather than as the moment it meant, and answered with the window next
-- to the one asked for. As a timestamptz the column holds the moment itself and
-- postgres compares instants, so there is no convention left to keep.
--
-- What is stored is UTC already, which is what the USING clause says.
ALTER TABLE scores
    ALTER COLUMN lastChangedAt TYPE TIMESTAMPTZ
        USING lastChangedAt AT TIME ZONE 'UTC';

-- Back to a moment in UTC without the zone that says so.
ALTER TABLE scores
    ALTER COLUMN lastChangedAt TYPE TIMESTAMP
        USING lastChangedAt AT TIME ZONE 'UTC';

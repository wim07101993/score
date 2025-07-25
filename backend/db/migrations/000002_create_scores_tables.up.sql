CREATE TABLE IF NOT EXISTS score_files
(
    id UUID PRIMARY KEY,
    content TEXT
);

CREATE TABLE IF NOT EXISTS scores
(
    id                 UUID PRIMARY KEY,
    work_title         TEXT NOT NULL,
    work_number        TEXT,
    movement_number    TEXT,
    movement_title     TEXT,
    creators_composers TEXT[],
    creators_lyricists TEXT[],
    languages          TEXT[],
    instruments        INSTRUMENT[],
    lastChangedAt      TIMESTAMP,
    tags               TEXT[],
    FOREIGN KEY (id)
        REFERENCES score_files(id)
        ON DELETE CASCADE
);

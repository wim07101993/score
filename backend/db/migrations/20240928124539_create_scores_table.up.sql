CREATE TABLE IF NOT EXISTS scores
(
    id          VARCHAR(36) PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    composers   VARCHAR(200),
    lyricists   VARCHAR(200),
    instruments VARCHAR(200)
);

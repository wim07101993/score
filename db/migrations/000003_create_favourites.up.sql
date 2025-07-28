CREATE TABLE IF NOT EXISTS favourites
(
    scoreId      UUID,
    userId       BIGINT,
    favouritedAt TIMESTAMP,
    PRIMARY KEY (scoreId, userId),
    FOREIGN KEY (scoreId) REFERENCES scores (id)
);
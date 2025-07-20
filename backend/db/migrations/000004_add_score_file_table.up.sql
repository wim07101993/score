CREATE TABLE IF NOT EXISTS score_files
(
    id UUID PRIMARY KEY,
    content BYTEA
);

ALTER TABLE scores
ADD FOREIGN KEY (id) REFERENCES score_files(id);
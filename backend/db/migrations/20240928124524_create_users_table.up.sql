CREATE TABLE IF NOT EXISTS users
(
    email         VARCHAR(300) PRIMARY KEY,
    name          VARCHAR(100)       NULL,
    google_id     VARCHAR(50) UNIQUE NULL,
    facebook_id   VARCHAR(50) UNIQUE NULL,
    is_user_admin BIT
);

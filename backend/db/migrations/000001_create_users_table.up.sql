CREATE TABLE IF NOT EXISTS users(
    email VARCHAR (300) PRIMARY KEY,
    name VARCHAR (100) NOT NULL,
    google_id VARCHAR (50) UNIQUE NOT NULL,
    facebook_id VARCHAR (50) UNIQUE NOT NULL
)
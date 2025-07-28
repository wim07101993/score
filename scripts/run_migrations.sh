#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
MIGRATIONS_DIR="$PROJECT_DIR"/db/migrations
DATABASE_URL="postgres://postgres:postgres@localhost:7432/score?sslmode=disable"

docker run -v "$MIGRATIONS_DIR":/migrations --network host migrate/migrate \
    -path=/migrations/ \
    -database "$DATABASE_URL" up

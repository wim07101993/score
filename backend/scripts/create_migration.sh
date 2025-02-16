#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
MIGRATIONS_DIR="$PROJECT_DIR"/db/migrations

NAME_OF_YOUR_MIGRATION=$1

docker run -v "$MIGRATIONS_DIR":/migrations --network host migrate/migrate \
    create \
    -ext .sql \
    -dir /migrations/ \
    -seq \
    "$NAME_OF_YOUR_MIGRATION"

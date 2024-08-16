#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
MIGRATIONS_DIR="$PROJECT_DIR"/db/migrations

 migrate -path "$MIGRATIONS_DIR" -database "postgres://scoreApi:password@localhost:7701/scores?sslmode=disable" up
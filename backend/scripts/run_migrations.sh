#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
MIGRATIONS_DIR="$PROJECT_DIR"/db/migrations

migrate \
  -source "file://$MIGRATIONS_DIR" \
  -database sqlite3://score.db up

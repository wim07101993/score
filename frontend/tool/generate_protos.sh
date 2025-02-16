#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
PROTOS_DIR="$PROJECT_DIR"/../backend/proto
GENERATED_DIR="$PROJECT_DIR"/lib/shared/api/generated
SYSTEM_PROTOS_DIR="$HOME/.local/bin/include/google/protobuf"

[[ ! -d "$GENERATED_DIR" ]] && mkdir -p "$GENERATED_DIR"

protoc \
  --dart_out=grpc:"$GENERATED_DIR" \
  --proto_path "$PROTOS_DIR" \
  "$PROTOS_DIR"/*.proto "$SYSTEM_PROTOS_DIR"/*.proto
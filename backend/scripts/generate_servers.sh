#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
PROTOS_DIR="$PROJECT_DIR"/proto
GENERATED_DIR="$PROJECT_DIR"/api/generated

[[ ! -d "$GENERATED_DIR" ]] && mkdir "$GENERATED_DIR"

protoc \
  --go_out="$GENERATED_DIR" \
  --go-grpc_out="$GENERATED_DIR" \
  --proto_path "$PROTOS_DIR" \
  "$PROTOS_DIR"/*

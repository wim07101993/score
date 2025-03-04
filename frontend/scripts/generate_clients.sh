#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
PROTOS_DIR="$PROJECT_DIR"/../backend/proto
GENERATED_DIR="$PROJECT_DIR"/src/client/generated

[[ ! -d "$GENERATED_DIR" ]] && mkdir "$GENERATED_DIR"

protoc \
  --js_out=import_style=commonjs:. \
  --grpc-web_out=import_style=commonjs,mode=grpcwebtext:. \
  --proto_path "$PROTOS_DIR" \
  "$PROTOS_DIR"/*

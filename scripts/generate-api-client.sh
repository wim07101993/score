#!/bin/bash

# Generates the Dart client the frontend talks to the API through, from the
# openapi document: the same document the backend is generated from, so the
# two cannot disagree about what the API is.
#
# The document is spread over a file per thing; the generator reads one
# document, so it is bundled into one first, with the same Redocly CI lints it
# with. The generator's settings are in frontend/tonik.yaml.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_DIR="$SCRIPT_DIR/.."
FRONTEND_DIR="$PROJECT_DIR"/frontend
BUNDLE="$(mktemp -d)"/openapi.yaml

cd "$PROJECT_DIR"
npx --yes @redocly/cli@2.44.1 bundle api/openapi-spec.yaml -o "$BUNDLE"

# Generated next to the package rather than over it: the app depends on the
# package by path, so `dart run` cannot resolve while it is gone.
OUT="$(mktemp -d)"
cd "$FRONTEND_DIR"
dart run tonik --config tonik.yaml --spec "$BUNDLE" --output-dir "$OUT"
rm -rf packages/score_api
mv "$OUT"/score_api packages/score_api
(cd packages/score_api && dart pub get)

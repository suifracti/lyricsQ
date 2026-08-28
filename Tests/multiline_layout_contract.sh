#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d /tmp/multiline-contract.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  Tests/multiline_layout_contract.swift \
  -o "$TMP_DIR/multiline_contract_test"

"$TMP_DIR/multiline_contract_test"

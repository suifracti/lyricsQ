#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d /tmp/grapheme-contract.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  Tests/grapheme_safe_range_contract.swift \
  -o "$TMP_DIR/grapheme-safe-range-contract"

"$TMP_DIR/grapheme-safe-range-contract"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-range-source-contract.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  Tests/timed_range_source_contract.swift \
  -o "$TMP_DIR/timed-range-source-contract"

"$TMP_DIR/timed-range-source-contract"

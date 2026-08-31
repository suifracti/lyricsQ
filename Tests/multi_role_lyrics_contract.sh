#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/multi-role-lyrics.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  "$ROOT_DIR/SpotifyLyrics/Models/Models.swift" \
  "$ROOT_DIR/Tests/multi_role_lyrics_contract.swift" \
  -o "$TMP_DIR/multi-role-lyrics-contract"

"$TMP_DIR/multi-role-lyrics-contract"

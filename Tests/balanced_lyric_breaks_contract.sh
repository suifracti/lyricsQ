#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
swiftc -parse-as-library "$ROOT/SpotifyLyrics/Models/Models.swift" "$ROOT/Tests/balanced_lyric_breaks_contract.swift" -o "$TMP_DIR/test"
"$TMP_DIR/test"

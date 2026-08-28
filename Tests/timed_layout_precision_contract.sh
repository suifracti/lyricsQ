#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-layout-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library SpotifyLyrics/Models/Models.swift Tests/timed_layout_precision_contract.swift -o "$TMP_DIR/layout_test"
"$TMP_DIR/layout_test"

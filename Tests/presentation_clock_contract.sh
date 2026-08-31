#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-clock-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library SpotifyLyrics/Models/Models.swift Tests/presentation_clock_contract.swift -o "$TMP_DIR/clock_test"
"$TMP_DIR/clock_test"

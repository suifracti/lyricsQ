#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-continuous-contract.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  Tests/continuous_progress_contract.swift \
  -o "$TMP_DIR/continuous-progress-contract"

"$TMP_DIR/continuous-progress-contract"

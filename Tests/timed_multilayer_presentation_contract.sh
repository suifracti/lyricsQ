#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$(mktemp -t timed_multilayer_presentation_contract_bin)"
trap 'rm -f "$BIN"' EXIT

swiftc -parse-as-library \
  "$ROOT/SpotifyLyrics/Models/Models.swift" \
  "$ROOT/SpotifyLyrics/Lyrics/JapaneseRomanizer.swift" \
  "$ROOT/SpotifyLyrics/Lyrics/JapaneseReadingPipeline.swift" \
  "$ROOT/SpotifyLyrics/Lyrics/JapaneseKanaGenerator.swift" \
  "$ROOT/Tests/timed_multilayer_presentation_contract.swift" \
  -o "$BIN"

SPOTIFYLYRICS_MECAB_PATH="${SPOTIFYLYRICS_MECAB_PATH:-/opt/homebrew/bin/mecab}" "$BIN"

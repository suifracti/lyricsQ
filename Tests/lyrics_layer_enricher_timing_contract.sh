#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d /tmp/enricher-timing.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  SpotifyLyrics/Lyrics/TrackIdentity.swift \
  SpotifyLyrics/Lyrics/LyricsModels.swift \
  SpotifyLyrics/Lyrics/AlignmentModels.swift \
  SpotifyLyrics/Lyrics/TrackAlias.swift \
  SpotifyLyrics/Lyrics/TrackMetadata.swift \
  SpotifyLyrics/Lyrics/TrackTextNormalizer.swift \
  SpotifyLyrics/Lyrics/JapaneseRomanizer.swift \
  SpotifyLyrics/Lyrics/JapaneseReadingPipeline.swift \
  SpotifyLyrics/Lyrics/JapaneseKanaGenerator.swift \
  SpotifyLyrics/Lyrics/LyricsQueryPlanner.swift \
  SpotifyLyrics/Lyrics/LyricsRecoveryModels.swift \
  Tests/lyrics_layer_enricher_timing_contract.swift \
  -o "$TMP_DIR/enricher_timing_test"

"$TMP_DIR/enricher_timing_test"

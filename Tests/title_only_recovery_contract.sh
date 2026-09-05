#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  "$ROOT_DIR/SpotifyLyrics/Models/Models.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/TrackIdentity.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsModels.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/AlignmentModels.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/TrackAlias.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/TrackMetadata.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/TrackTextNormalizer.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/JapaneseRomanizer.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/JapaneseReadingPipeline.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/JapaneseKanaGenerator.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsQueryPlanner.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsSafeMatcher.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsRecoveryModels.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsE2ELog.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsSearchManager.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/TimedTranscript.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LRCParser.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LyricsMatcher.swift" \
  "$ROOT_DIR/SpotifyLyrics/Lyrics/LRCLIBLyricsProvider.swift" \
  "$ROOT_DIR/Tests/title_only_recovery_contract.swift" \
  -o "$TMP_DIR/title-only-recovery-contract"

"$TMP_DIR/title-only-recovery-contract" "$@"

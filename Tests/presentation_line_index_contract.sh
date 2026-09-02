#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/SpotifyLyrics/Services/PlaybackState.swift"
V3="$ROOT/SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift"
CANVAS="$ROOT/SpotifyLyrics/Views/Components/LyricsCanvasView.swift"
FULLSCREEN="$ROOT/SpotifyLyrics/Views/Fullscreen/FullScreenLyricsView.swift"
MODELS="$ROOT/SpotifyLyrics/Lyrics/LyricsModels.swift"

for file in "$STATE" "$V3" "$CANVAS" "$FULLSCREEN" "$MODELS"; do
  test -f "$file" || { echo "FAIL: missing $file" >&2; exit 1; }
done

require() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Eq "$pattern" "$file"; then
    echo "FAIL: $label ($file does not contain /$pattern/)" >&2
    exit 1
  fi
}

forbid() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    echo "FAIL: $label ($file contains /$pattern/)" >&2
    exit 1
  fi
}

require "$STATE" 'calibrationInterval: TimeInterval = 1\.0' '1s Spotify calibration interval'
require "$STATE" '@Published public private\(set\) var liveCurrentLineIndex' 'stored published line index'
require "$STATE" 'lineBoundaryTask' 'boundary wake task'
require "$STATE" 'syncPublishedLineIndex' 'index sync helper'
require "$STATE" 'source: .boundary' 'index updates at lyric boundaries'
require "$STATE" 'LineIndexSource' 'poll/seek/boundary sources'
require "$STATE" 'shouldSuppressPollRegression' 'short-lived poll anti-regression'
require "$MODELS" 'func nextBoundaryTime' 'timeline next-boundary helper'
require "$V3" 'let currentIndex = state.currentLineIndex' 'V3 reads published index'
require "$V3" 'onChange\(of: currentIndex\)' 'V3 scrolls on index change'
require "$CANVAS" 'onChange\(of: state.currentLineIndex\)' 'canvas scrolls on index change'
require "$FULLSCREEN" 'onChange\(of: state.liveCurrentLineIndex\)' 'fullscreen scrolls on index change'

forbid "$V3" 'LyricsTimeline.activeLineIndex\(' 'V3 must not recompute index from currentTime'
forbid "$V3" 'onChange\(of: state.currentTime\)' 'V3 must not scroll on currentTime ticks'
forbid "$CANVAS" 'onChange\(of: state.currentTime\)' 'canvas must not scroll on currentTime ticks'
forbid "$FULLSCREEN" 'onChange\(of: state.currentTime\)' 'fullscreen must not scroll on currentTime ticks'

# Karaoke fill may use TimelineView inside the active row only.
require "$V3" 'TimelineView\(\.animation\(minimumInterval: 1\.0 / 60\.0' 'timed fill may use display-rate'

echo 'PASS: presentation line index contract'

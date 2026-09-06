#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$ROOT/SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift"
TOKENS="$ROOT/SpotifyLyrics/Design/LyricsDesignTokens.swift"

require_view() {
  local pattern="$1"
  local label="$2"
  if ! grep -Eq "$pattern" "$VIEW"; then
    echo "FAIL: $label (missing /$pattern/)" >&2
    exit 1
  fi
}

require_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Eq "$pattern" "$file"; then
    echo "FAIL: $label (missing /$pattern/)" >&2
    exit 1
  fi
}

require_file "$TOKENS" 'enum LyricsTransitionStyle' 'shared lyric transition policy'
require_view 'LyricsTransitionPolicy\.animation\(reduceMotion: reduceMotion\)' 'lyric animation source'
require_file "$TOKENS" 'smoothRelayoutV1' 'smooth lyric transition preset'
require_file "$TOKENS" 'lyricDuration' 'dedicated lyric transition duration'
require_view 'onChange\(of: currentIndex\)' 'current-line transition trigger'
require_view 'private var v3LineFollowAnimation' 'V3 uses a dedicated short follow animation'
require_view 'withAnimation\(v3LineFollowAnimation, action\)' 'scroll follows the already-published active line'
require_view '\.easeOut\(duration: 0\.12\)' 'V3 line follow has no spring overshoot and stays short'

if grep -q 'value: state\.liveCurrentLineIndex' "$VIEW"; then
  echo 'FAIL: V3 lyric stack still animates the entire document on every current-line update' >&2
  exit 1
fi

if ! grep -qF '.animation(nil, value: isActive)' "$VIEW"; then
  echo 'FAIL: V3 active-line handoff must be immediate' >&2
  exit 1
fi

if sed -n '/private func scrollToCurrentLine/,/^    }/p' "$VIEW" | grep -q 'LyricsTransitionPolicy.perform'; then
  echo 'FAIL: V3 current-line handoff still delegates to the 0.34s shared relayout animation' >&2
  exit 1
fi

echo 'V3 lyric transition contract: PASS'

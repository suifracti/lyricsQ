#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
V3="$ROOT_DIR/SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift"
CLOCK="$ROOT_DIR/Tests/presentation_clock_contract.sh"

test -f "$V3" || { echo "FAIL: missing V3 main window" >&2; exit 1; }

bash "$CLOCK" >/dev/null

grep -Fq 'LyricsPresentationOffsetControl(settings: settings)' "$V3" || {
  echo 'FAIL: main playback page has no shared lyrics presentation offset entry' >&2
  exit 1
}

grep -Fq 'isLyricsTimePresented.toggle()' "$V3" || {
  echo 'FAIL: main playback page has no direct lyrics time toolbar action' >&2
  exit 1
}

grep -Fq 'V3LyricsTimePopover(settings: settings)' "$V3" || {
  echo 'FAIL: lyrics time action does not open its direct popover' >&2
  exit 1
}

grep -Fq 'lyricsTimeToolbarLabel' "$V3" || {
  echo 'FAIL: lyrics time toolbar action has no visible current-offset status' >&2
  exit 1
}

grep -Fq 'Button("恢复默认")' "$V3" || {
  echo 'FAIL: direct lyrics time popover has no reset action' >&2
  exit 1
}

if grep -Eq 'mainWindowLyricsOffset|desktopLyricsOffset' "$V3"; then
  echo 'FAIL: main playback page introduced a second offset state' >&2
  exit 1
fi

echo 'PASS: shared lyrics presentation offset contract'

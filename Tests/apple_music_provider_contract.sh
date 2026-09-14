#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAYBACK="$ROOT_DIR/SpotifyLyrics/Providers/PlaybackProvider.swift"
AM_PROVIDER="$ROOT_DIR/SpotifyLyrics/Providers/AppleMusicDesktopProvider.swift"
CONTRACT="$ROOT_DIR/Tests/apple_music_provider_contract.swift"

test -f "$PLAYBACK"
test -f "$AM_PROVIDER"
test -f "$CONTRACT"

# Static invariants
grep -q 'private actor AppleMusicAppleScriptProcessRunner' "$AM_PROVIDER"
grep -q '/usr/bin/osascript' "$AM_PROVIDER"
grep -q 'Apple Music Apple Events 请求超时' "$AM_PROVIDER"
grep -q 'process.terminate()' "$AM_PROVIDER"
grep -q 'SIGKILL' "$AM_PROVIDER"
grep -q 'private let scriptRunner' "$AM_PROVIDER"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
    "$PLAYBACK" \
    "$AM_PROVIDER" \
    "$CONTRACT" \
    -o "$TMP_DIR/apple-music-contract"

"$TMP_DIR/apple-music-contract"

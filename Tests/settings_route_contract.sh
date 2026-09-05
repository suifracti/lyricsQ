#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-settings-route.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
swiftc -parse-as-library Tests/fixtures/settings_playback_stub.swift Tests/fixtures/settings_route_host.swift SpotifyLyrics/Windows/MenuBarLyricsController.swift -o "$TMP_DIR/settings-contract"
"$TMP_DIR/settings-contract"

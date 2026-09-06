#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_TMP_DIR="$(mktemp -d /tmp/kugou-contract.XXXXXX)"
trap 'rm -rf "$TASK_TMP_DIR"' EXIT
swiftc -parse-as-library SpotifyLyrics/Models/Models.swift SpotifyLyrics/Lyrics/TrackIdentity.swift SpotifyLyrics/Lyrics/AlignmentModels.swift SpotifyLyrics/Lyrics/LyricsModels.swift SpotifyLyrics/Lyrics/LRCParser.swift SpotifyLyrics/Providers/KugouExperimentalLyricsProvider.swift Tests/kugou_provider_contract.swift -o "$TASK_TMP_DIR/contract"
"$TASK_TMP_DIR/contract"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/track-metadata-copy-contract.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  -framework AppKit \
  "$ROOT_DIR/SpotifyLyrics/Views/Components/TrackMetadataCopy.swift" \
  "$ROOT_DIR/Tests/track_metadata_copy_contract.swift" \
  -o "$TMP_DIR/track-metadata-copy-contract"

"$TMP_DIR/track-metadata-copy-contract"

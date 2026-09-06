#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$(mktemp -t provider-expansion-contract)"
trap 'rm -f "$BIN"' EXIT
swiftc -parse-as-library "$ROOT/SpotifyLyrics/Settings/LyricsProviderConfiguration.swift" "$ROOT/Tests/provider_expansion_configuration_contract.swift" -o "$BIN"
"$BIN"

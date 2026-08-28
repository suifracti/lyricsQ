#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d /tmp/ruby-timed-contract.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library \
  SpotifyLyrics/Models/Models.swift \
  Tests/ruby_timed_projection_contract.swift \
  -o "$TMP_DIR/ruby_timed_contract_test"

"$TMP_DIR/ruby_timed_contract_test"

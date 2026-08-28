#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
TMP_DIR="$(mktemp -d /tmp/spotifylyrics-layout-meas.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc -parse-as-library -framework CoreText -framework CoreGraphics -framework Foundation \
  Tests/layout_measurement_contract.swift -o "$TMP_DIR/meas"
"$TMP_DIR/meas"

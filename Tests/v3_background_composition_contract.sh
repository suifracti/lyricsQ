#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The former source-string test both accepted the obscured cover and required
# its dark overlay. Run production geometry instead; native render evidence
# separately verifies sharpness, all four image edges and style distinction.
bash "$ROOT/Tests/v3_responsive_geometry_contract.sh"

# Retain the pre-existing persistence compatibility checks independently of
# the retired rendering string assertions.
SETTINGS="$ROOT/SpotifyLyrics/Settings/AppSettingsStore.swift"
for key in v3BackdropBlurAmbient v3BackdropBlurStage v3BackdropBlurClassic; do
  grep -q "$key" "$SETTINGS" || { echo "FAIL: missing per-mode blur key $key" >&2; exit 1; }
done
grep -q 'v3BlurByPresentation' "$SETTINGS" || { echo 'FAIL: no per-mode blur memory' >&2; exit 1; }

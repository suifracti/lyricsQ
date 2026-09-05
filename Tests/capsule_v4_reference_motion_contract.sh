#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$ROOT_DIR/SpotifyLyrics/Views/Capsule/CapsuleLyricsView.swift"

# The reference pass requires a top-attached shoulder rather than a flat
# rectangle, one explicit geometry transaction for the island morph, and a
# short immediate content cross-fade so the shared anchor does not pop between
# states.
grep -F 'topAttachedCornerRadius' "$VIEW" >/dev/null
grep -F 'CapsuleV4Motion.geometryAnimation' "$VIEW" >/dev/null
grep -F 'spring(response: 0.34, dampingFraction: 0.9)' "$VIEW" >/dev/null
grep -F 'CapsuleV4Motion.contentAnimation' "$VIEW" >/dev/null
grep -F 'contentFadeDelay = 0.0' "$VIEW" >/dev/null
grep -F '.transition(.opacity)' "$VIEW" >/dev/null

echo "capsule v4 reference motion contract passed"

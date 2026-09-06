#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d /tmp/floating-outline-contract.XXXXXX)"
trap 'rm -rf "$TASK_TMP"' EXIT
python3 - "$ROOT" "$TASK_TMP" <<'PY'
from pathlib import Path
import sys
root, temporary = map(Path, sys.argv[1:])
source = (root/'SpotifyLyrics/Views/Floating/FloatingLyricsView.swift').read_text()
primitive = source[source.index('struct OutlinedLyricText:'):source.index('struct FloatingDesktopPalette')]
(temporary/'OutlinedLyricText.swift').write_text('import AppKit\nimport SwiftUI\n'+primitive)
PY
swiftc -parse-as-library "$TASK_TMP/OutlinedLyricText.swift" "$ROOT/Tests/floating_outline_render_contract.swift" -o "$TASK_TMP/contract"
"$TASK_TMP/contract"

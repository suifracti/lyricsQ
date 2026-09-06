#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN="$ROOT/SpotifyLyrics/Main.swift"

# Window actions extend the native Window menu rather than adding a second one.
if grep -Fq 'CommandMenu("窗口")' "$MAIN"; then
  echo "Window actions must not create a duplicate top-level Window menu" >&2
  exit 1
fi
grep -Fq 'CommandGroup(after: .windowArrangement)' "$MAIN"

registered_count="$({ awk '
    /\.commands[[:space:]]*\{/ {
        in_commands = 1
        next
    }
    in_commands && /appCommands/ {
        count += 1
        in_commands = 0
        next
    }
    in_commands && /^[[:space:]]*\}/ {
        in_commands = 0
    }
    END { print count + 0 }
' "$MAIN"; })"

if [[ "$registered_count" != "1" ]]; then
  echo "Expected appCommands to be registered exactly once, found $registered_count" >&2
  exit 1
fi

preview_commands_count="$(grep -Fc 'PresentationPreviewCommands()' "$MAIN")"
if [[ "$preview_commands_count" != "1" ]]; then
  echo "Expected PresentationPreviewCommands to be registered exactly once, found $preview_commands_count" >&2
  exit 1
fi

if ! grep -Fq 'path = SpotifyLyrics.icns' "$ROOT/SpotifyLyrics.xcodeproj/project.pbxproj"; then
  echo "SpotifyLyrics.icns must be declared in the Xcode project" >&2
  exit 1
fi

if ! grep -Fq 'SpotifyLyrics.icns in Resources' "$ROOT/SpotifyLyrics.xcodeproj/project.pbxproj"; then
  echo "SpotifyLyrics.icns must be copied into the app Resources phase" >&2
  exit 1
fi

if ! grep -Fq '<key>CFBundleIconFile</key>' "$ROOT/SpotifyLyrics/Info-Additions.plist" \
  || ! grep -Fq '<string>SpotifyLyrics.icns</string>' "$ROOT/SpotifyLyrics/Info-Additions.plist"; then
  echo "Info-Additions.plist must declare the bundled SpotifyLyrics.icns" >&2
  exit 1
fi

echo "APP_COMMANDS_REGISTRATION_CONTRACT_PASSED"

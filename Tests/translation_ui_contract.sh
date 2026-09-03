#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}/.."
FILE="$ROOT/SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift"

for needle in \
  'translationSection' \
  'translationProgressMessage' \
  '重新翻译' \
  '锁定当前翻译' \
  '删除当前翻译' \
  'selectTranslation' \
  'lockSelectedTranslation' \
  'deleteSelectedTranslation'; do
  grep -F "$needle" "$FILE" >/dev/null
done

print "translation UI contract passed"

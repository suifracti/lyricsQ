#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$ROOT_DIR/SpotifyLyrics/Views/Fullscreen/FullScreenLyricsView.swift"
V3="$ROOT_DIR/SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift"
CONTROLLER="$ROOT_DIR/SpotifyLyrics/Windows/FullScreenLyricsWindowController.swift"
MANAGER="$ROOT_DIR/SpotifyLyrics/Windows/WindowManager.swift"
require() { grep -Fq "$2" "$1" || { echo "FAIL: $3" >&2; exit 1; }; }
require "$VIEW" 'AppleMusicImmersiveV3WindowView' 'fullscreen uses maintained player'
require "$VIEW" 'liveOnly: true' 'fullscreen restricts projection to playback'
require "$VIEW" 'settings: AppSettingsStore' 'same injected appearance settings'
require "$V3" 'liveOnly ? state.liveLyrics : state.lyrics' 'live lyrics isolation'
require "$V3" 'liveOnly ? state.liveLyricsState : state.lyricsState' 'live state isolation'
require "$V3" 'liveOnly ? state.liveLyricsAreSynchronized : state.lyricsAreSynchronized' 'live timing isolation'
require "$V3" 'liveOnly ? state.liveCurrentLineIndex : state.currentLineIndex' 'live index isolation'
require "$V3" 'liveOnly ? state.liveLyricsSessionRevision : state.lyricsSessionRevision' 'document reset isolation'
require "$V3" 'liveOnly ? state.currentTrack : state.displayedTrack' 'copy/seek metadata isolation'
require "$V3" '!liveOnly && state.isShowingSearchPreview' 'preview does not disable live ruby correction'
require "$V3" 'LyricsCopyText.format(documentLines)' 'copy uses scoped document'
require "$V3" 'if !liveOnly {' 'search hidden on live-only surface'
require "$MANAGER" 'temporarilyHideForFullScreen' 'auxiliary snapshot'
require "$MANAGER" 'restoreAfterFullScreen' 'auxiliary restoration'
if grep -Eq 'Timer|LyricsProvider|LyricsSessionController|TranslationSessionController' "$VIEW" "$CONTROLLER"; then
  echo 'FAIL: fullscreen creates independent playback ownership' >&2; exit 1
fi
require "$V3" 'onOpenEditor: liveOnly ? { MenuBarLyricsController.shared.openEditor() } : nil' 'fullscreen editor uses a scene-bound callback'
require "$ROOT_DIR/SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift" 'if let onOpenEditor { onOpenEditor() }' 'editor honors injected routing'
require "$ROOT_DIR/SpotifyLyrics/Views/MainWindow/MainLyricsWindowView.swift" 'setOpenEditorHandler' 'production scene installs editor route'
require "$ROOT_DIR/Tools/experience_visual_host/VisualHost.swift" 'setOpenEditorHandler' 'fixture installs editor route'
bash "$ROOT_DIR/Tests/fullscreen_window_behavior_contract.sh"
echo 'fullscreen lyrics static contract passed'

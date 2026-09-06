#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTROLLER="$ROOT_DIR/SpotifyLyrics/Windows/FullScreenLyricsWindowController.swift"
MANAGER="$ROOT_DIR/SpotifyLyrics/Windows/WindowManager.swift"
require() { grep -Fq "$2" "$1" || { echo "FAIL: $3" >&2; exit 1; }; }
require "$CONTROLLER" 'class FullScreenLyricsWindow: NSWindow' 'native fullscreen window'
require "$CONTROLLER" 'window.collectionBehavior = [.fullScreenPrimary, .fullScreenDisallowsTiling]' 'native primary Space'
require "$CONTROLLER" 'window.toggleFullScreen(nil)' 'AppKit fullscreen transition'
require "$CONTROLLER" 'case .entering: exitRequested = true' 'exit during entry is queued'
require "$CONTROLLER" 'windowDidEnterFullScreen' 'entry lifecycle'
require "$CONTROLLER" 'windowDidExitFullScreen' 'exit lifecycle'
require "$CONTROLLER" 'windowDidFailToEnterFullScreen' 'failed entry cleanup'
require "$CONTROLLER" 'windowDidFailToExitFullScreen' 'failed exit remains recoverable'
require "$CONTROLLER" 'override func cancelOperation' 'Escape uses responder chain'
require "$CONTROLLER" 'guard attachedSheet == nil' 'Escape respects sheets'
require "$CONTROLLER" 'willUseFullScreenPresentationOptions' 'presentation scoped to native window'
require "$CONTROLLER" 'options.formUnion([.autoHideDock, .autoHideMenuBar])' 'Dock and menu autohide'
require "$CONTROLLER" 'isReleasedWhenClosed = false' 'retained window'
require "$MANAGER" 'fullScreenAuxiliaryVisibilitySnapshot' 'transient auxiliary snapshot'
require "$MANAGER" 'finishFullScreenHide' 'restore after transition completion'
require "$MANAGER" 'exitFullScreenToMainWindow' 'main window exit route'
if grep -Eq 'NSPanel|nonactivatingPanel|canJoinAllSpaces|fullScreenAuxiliary|NSApp.presentationOptions|addLocalMonitorForEvents' "$CONTROLLER"; then
  echo 'FAIL: fullscreen retains a floating/global presentation workaround' >&2; exit 1
fi
if grep -Eq 'seek\(|seekTo' "$CONTROLLER"; then
  echo 'FAIL: window lifecycle seeks playback' >&2; exit 1
fi
echo 'fullscreen window behavior contract passed'

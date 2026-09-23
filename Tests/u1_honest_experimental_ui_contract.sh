#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
read = lambda path: (root / path).read_text()
failures = []

def require(condition, message):
    if not condition:
        failures.append(message)

def swift_body(source, marker):
    start = source.find(marker)
    if start < 0:
        return ""
    open_brace = source.find("{", start)
    depth = 0
    for index in range(open_brace, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[start:index + 1]
    return ""

classic = read("SpotifyLyrics/Views/MainWindow/ImmersiveSplitWindowView.swift")
require('Label("收藏"' not in classic and 'Label("更多"' not in classic,
        "Classic still exposes clickable Favorite/More placeholders")

row = read("SpotifyLyrics/Views/Components/DirectionD/DirectionDLyricRowView.swift")
for action, explanation in [
    ("onEditTranslation", "Direction D"),
    ("onAdjustPhonetics", "Direction D"),
    ("onAdjustTiming", "Direction D"),
]:
    button = row.find(f"Button(action: {action})")
    next_button = row.find("Button(action:", button + 1) if button >= 0 else -1
    fragment = row[button: next_button if next_button >= 0 else len(row)]
    require(button >= 0 and ".disabled(true)" in fragment and ".help(" in fragment,
            f"row action {action} can still be triggered without a real operation and reason")

inspector = read("SpotifyLyrics/Views/Components/DirectionD/DirectionDInspectorView.swift")
require(not any(fake in inspector for fake in ("当前使用", "当前显示", "已完成")),
        "inspector still makes fixed current/completed claims")
inspector_body = swift_body(inspector, "public var body: some View")
require(inspector_body.count("Button(") <= 1,
        "inspector still presents non-dismissal buttons without a live route")
require(".onTapGesture {}" not in inspector_body,
        "inspector still presents an empty history gesture")
require(any(term in inspector_body for term in ("暂无", "尚未接入", "实验界面")),
        "inspector does not explain the unavailable workbench capabilities")

main = read("SpotifyLyrics/Views/MainWindow/MainLyricsWindowView.swift")
require("DirectionDActionRouter.performManualLyricsImport" in main,
        "main Direction D import does not use the tested prepare-then-open action")
require("prepare: { state.prepareManualLyricsFromTXT() }" in main and
        'openWindow(id: "lyrics-editor")' in main,
        "main Direction D TXT import is not bound to the real preparation and editor routes")
for route in (
    "isSearchPresented = true", "openSettings()", "state.retryLyrics()",
    "AutomaticAlignmentJobController.shared.retry()",
    "AutomaticAlignmentJobController.shared.cancelCurrentJob(userInitiated: true)",
):
    require(route in main, f"a real Direction D route was removed: {route}")

experimental_host = read("SpotifyLyrics/Views/Components/DirectionD/DirectionDExperimentalProductHost.swift")
require("SongSearchPopover" in experimental_host and "openSettings()" in experimental_host,
        "Debug Direction D host does not preserve real search and Settings routes")
require("DirectionDActionRouter.performManualLyricsImport" in experimental_host,
        "Debug Direction D import does not open the editor after successful preparation")
app = read("SpotifyLyrics/Main.swift")
require("DirectionDDebugMainWindowSceneHost(" in app,
        "Debug Direction D main scene still uses router defaults without search/editor presentation")

prefs = read("SpotifyLyrics/Views/Components/LyricsPreferencesPopover.swift")
require("WindowManager.shared.toggleCapsule(state: playbackState)" in prefs,
        "Capsule toggle no longer reaches its production window controller")
capsule_start = prefs.find('Text("显示窗口")')
capsule_end = prefs.find('modeButton("全屏歌词"', capsule_start)
capsule_controls = prefs[capsule_start:capsule_end]
require("Capsule" in capsule_controls and "实验" in capsule_controls,
        "Capsule entry has no scoped experimental explanation")

operations = read("SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift")
translation_section = swift_body(operations, "private var translationSection: some View")
require("state.translateCurrentLyrics()" in translation_section and "实验" in translation_section,
        "AI translation action is missing or has no experimental explanation")
alignment_section = swift_body(operations, "private var alignmentSection: some View")
require("state.alignCurrentLyricsWithLocalAudio()" in alignment_section and
        "state.confirmAlignmentPreview(saveLocal: true)" in alignment_section and
        "实验" in alignment_section,
        "local alignment/confirmation route is missing or has no experimental explanation")

settings = read("SpotifyLyrics/Views/Settings/SettingsRootView.swift")
automatic_alignment_setting = swift_body(settings, 'Section("自动排轴")')
require("automaticAlignmentEnabled" in automatic_alignment_setting and "实验" in automatic_alignment_setting,
        "automatic alignment setting lacks a scoped experimental explanation")
require("Apple Music" in automatic_alignment_setting and "Spotify Desktop" in automatic_alignment_setting,
        "automatic alignment source capability boundary is not explained in Settings")

catalog = read("SpotifyLyrics/Design/PresentationCatalog.swift")
require('entry("mainWindow.directionD.v4"' in catalog and
        '.experimental, .release' in catalog,
        "Direction D must remain Release-reachable and categorized as experimental")
model = read("SpotifyLyrics/Design/MainWindowLayoutStyle.swift")
require("appleMusicImmersiveV3" in model,
        "U1 changed the existing main-window default/layout model")

if failures:
    for failure in failures:
        print(f"FAIL: {failure}")
    raise SystemExit(1)

print("U1 honest experimental UI source/route contract: PASS")
PY

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
swiftc \
  "$ROOT/SpotifyLyrics/Design/DirectionD/DirectionDActionRouter.swift" \
  "$ROOT/Tests/u1_honest_experimental_ui_contract.swift" \
  -o "$TMP/u1-honest-experimental-ui-contract"
"$TMP/u1-honest-experimental-ui-contract"

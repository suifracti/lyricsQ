# Spotify Lyrics — Other Windows & Secondary Surfaces Read-Only Audit

## 1. Executive Summary & Preflight

- **Audit Date**: 2026-09-03
- **Audit Target**: All user-facing windows, panels, popovers, sheets, and embedded tool surfaces outside Main Window V3 and Settings Center.
- **Source of Truth**:
  - Worktree: `/private/tmp/spotifylyrics-other-windows-audit`
  - Branch: `antigravity/other-windows-audit`
  - Base Commit: `origin/main = cc4230fc771997796a819233270de783dc37f16b` (Merge PR #13)
  - Main Working Tree: `/Users/apple/backup/sptifylyrics` (isolated, dirty, strictly untouched)
- **Scope Rule**: Read-Only Audit. 0 Swift changes in this turn.
- **Audit Objective**:
  1. Map the complete inventory of secondary surfaces across the codebase with exact line ranges.
  2. Establish a clear, structured surface counting model separating primary surfaces, toolbar attachments, child sheets/popovers, embedded tools, legacy dead code, and debug scenes.
  3. Classify every surface by user-facing name, Swift symbol, file path, line range, entry point, and ownership domain.
  4. Audit current visual language (dimensions, materials, header hierarchy, density, corner radii).
  5. Verify boundary integrity against frozen baselines (V3 Visual Baseline, V3 Toolbar, Settings Center).
  6. Identify window-level UX issues (Blocker / Relevant / Incidental / Speculative).
  7. Provide runtime UI sampling evidence.
  8. Formally define what "Unify Other Windows" actually means across Group A/B/C/D.
  9. Demarcate explicit deferral boundaries for the upcoming `Recovery / Search / Import E2E` roadmap.

---

## 2. Complete Secondary Surface Inventory & Classification

### 2.1 Surface Counting Model & Grand Totals

To ensure 100% precision and avoid ambiguous groupings, surfaces are classified into six mutually exclusive categories with individual item accounting:

```text
================================================================================
SECONDARY SURFACE INVENTORY COUNT MODEL
================================================================================
1. USER_REACHABLE_PRIMARY_SURFACES        =  5  (Auxiliary panels & Editor window)
2. USER_REACHABLE_TOOLBAR_ATTACHMENTS      =  5  (V3 toolbar popovers & menus)
3. USER_REACHABLE_CHILD_SHEETS_POPOVERS   = 10  (Modal sheets & row-level popovers)
4. TRANSITIONAL_EMBEDDED_TOOLS            =  4  (Settings Center tool destinations)
--------------------------------------------------------------------------------
TOTAL_USER_REACHABLE_SURFACES             = 24
--------------------------------------------------------------------------------
5. UNREACHABLE_LEGACY                     =  1  (Orphaned dead code popover)
6. INTERNAL_DEBUG                         =  5  (#if DEBUG windows & assist sheet)
--------------------------------------------------------------------------------
TOTAL_INVENTORIED_SECONDARY_SURFACES      = 30
--------------------------------------------------------------------------------
EXCLUDED_MAIN_WINDOW_LEGACY_LAYOUTS       =  1  (ImmersiveSplitWindowView)
================================================================================
```

### 2.2 Category 1: User-Reachable Primary Surfaces (Count: 5)
*Independent floating panels and secondary window scenes reachable during standard usage:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Entry Point / Trigger | Ownership Domain |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Floating Lyrics** | `FloatingLyricsPanel`<br>`FloatingLyricsWindowController`<br>`FloatingLyricsView` | `SpotifyLyrics/Windows/FloatingLyricsWindowController.swift`<br>`SpotifyLyrics/Views/Floating/FloatingLyricsView.swift` | L5–13<br>L14–286<br>L6–250 | • Menu `窗口 -> 显示/隐藏悬浮歌词` (`Cmd+Opt+F`)<br>• Toolbar Window Mode Menu -> `悬浮歌词`<br>• Launch restoration | Presentation Surface |
| 2 | **Top Capsule** | `CapsuleLyricsPanel`<br>`CapsuleLyricsWindowController`<br>`CapsuleLyricsView` | `SpotifyLyrics/Windows/CapsuleLyricsWindowController.swift`<br>`SpotifyLyrics/Views/Capsule/CapsuleLyricsView.swift` | L5–46<br>L47–590<br>L46–981 | • Menu `窗口 -> 显示/隐藏顶部胶囊` (`Cmd+Opt+C`)<br>• Toolbar Window Mode Menu -> `顶部胶囊`<br>• Launch restoration | Presentation Surface |
| 3 | **FullScreen Lyrics** | `FullScreenLyricsPanel`<br>`FullScreenLyricsWindowController`<br>`FullScreenLyricsView` | `SpotifyLyrics/Windows/FullScreenLyricsWindowController.swift`<br>`SpotifyLyrics/Views/Fullscreen/FullScreenLyricsView.swift` | L5–20<br>L21–201<br>L6–348 | • Menu `窗口 -> 显示/隐藏全屏歌词` (`Cmd+Opt+G`)<br>• Toolbar Window Mode Menu -> `全屏歌词`<br>• Dismissed via `Esc` | Presentation Surface |
| 4 | **MenuBar Popover** | `MenuBarLyricsController`<br>`MenuBarLyricsPopoverView` | `SpotifyLyrics/Windows/MenuBarLyricsController.swift`<br>`SpotifyLyrics/Views/MenuBar/MenuBarLyricsPopoverView.swift` | L59–332<br>L3–153 | • macOS Menu Bar status item click | Presentation Surface / Quick Control |
| 5 | **Lyrics Editor Window** | `Window("歌词编辑", id: "lyrics-editor")`<br>`LyricsEditorWindowView` | `SpotifyLyrics/Main.swift`<br>`SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift` | L79–84<br>L5–551 | • `CurrentSongOperationsView` ("编辑当前版本" / "空白歌词编辑器")<br>• Capsule ("编辑歌词") | Current-Song Operation & Data Tool |

### 2.3 Category 2: User-Reachable Toolbar Attachments (Count: 5)
*Popovers and menus anchored directly to the V3 floating capsule toolbar:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Entry Point / Trigger | Ownership Domain |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 6 | **Song Search Popover** | `SongSearchPopover`<br>Toolbar trigger `searchButton` | `SpotifyLyrics/Views/Components/SongSearchPopover.swift`<br>`SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` | L4–110<br>L746–760 | • Toolbar `magnifyingglass` button | Recovery & Search Workflow<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 7 | **Current Song Operations Popover** | `CurrentSongOperationsView`<br>Toolbar trigger `currentSongOperationsButton` | `SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift`<br>`SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` | L6–990<br>L762–775 | • Toolbar `music.note.list` button | Current-Song Operation |
| 8 | **V3 Visual Tuning Popover** | `V3VisualTuningPopoverView`<br>Toolbar trigger `layoutMenu` | `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` | L2391–2540<br>L777–791 | • Toolbar `rectangle.3.group` button | Presentation Surface Tuning<br>(V3 Baseline Frozen) |
| 9 | **Provider Status Menu** | `providerStatusMenu` | `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` | L722–745 | • Toolbar Provider status dot indicator | Runtime Status & Recovery<br>(V3 Baseline Frozen) |
| 10 | **Window Mode Menu** | `windowModeMenu` | `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` | L684–720 | • Toolbar Window Mode capsule button | Window Presentation Mode Switching |

### 2.4 Category 3: User-Reachable Child Sheets & Popovers (Count: 10)
*Modal sheets and contextual popovers triggered from other secondary surfaces or canvas rows:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Entry Point / Trigger | Ownership Domain |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 11 | **Lyrics Version Picker Sheet** | `LyricsVersionPickerView` | `SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift` | L921–990 | • `CurrentSongOperationsView` ("选择歌词版本") | Current-Song Operation |
| 12 | **Reading Version Editor Sheet** | `ReadingVersionEditorView` | `SpotifyLyrics/Views/Components/ReadingVersionEditorView.swift` | L3–62 | • `CurrentSongOperationsView` ("编辑读音") | Current-Song Operation |
| 13 | **Translation Candidate Preview Sheet** | `TranslationCandidatePreviewView` | `SpotifyLyrics/Views/Components/CurrentSongOperationsView.swift` | L855–920 | • `CurrentSongOperationsView` (点击翻译候选行) | Recovery & Translation<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 14 | **Lyrics Candidate Preview Sheet** | `LyricsCandidatePreviewSheet` | `SpotifyLyrics/Views/Components/LyricsCanvasView.swift` | L927–995 | • `LyricsCanvasView` (无歌词错误状态下点击候选) | Recovery & Search<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 15 | **Personal Library Folder Import Sheet** | `PersonalLibraryImportPreviewSheet` | `SpotifyLyrics/Views/Settings/PersonalLyricsLibraryView.swift` | L663–747 | • `PersonalLyricsLibraryView` ("同步文件夹" / 导入文件夹) | Recovery & Import<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 16 | **Personal Data Archive Import Sheet** | `PersonalDataImportPreviewSheet` | `SpotifyLyrics/Views/Settings/PersonalLyricsLibraryView.swift` | L748–847 | • `PersonalLyricsLibraryView` ("导入数据归档") | Recovery & Import<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 17 | **Alignment Preview Sheet** | `AlignmentPreviewView` | `SpotifyLyrics/Views/Components/AlignmentPreviewView.swift` | L6–100 | • 主画布对齐完成时弹出对齐证据报告 | Recovery & Diagnostic<br>(`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`) |
| 18 | **Direction D Line Context Popover** | `DirectionDLyricRowView` | `SpotifyLyrics/Views/Components/DirectionD/DirectionDLyricRowView.swift` | L94–220 | • Direction D 歌词行悬浮省略号按钮 | Experimental Inline Tuning |
| 19 | **Settings Translation Prompt Preview Sheet** | `TranslationPromptPreviewView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L903–932 | • Settings -> AI 翻译 -> "查看当前 Prompt 内容" | Global Configuration<br>(Settings Center Frozen) |
| 20 | **Settings Translation Profiles Sheet** | `TranslationProfilesView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L782–902 | • Settings -> AI 翻译 -> "管理提示词预设" | Global Configuration<br>(Settings Center Frozen) |

### 2.5 Category 4: Transitional Embedded Tools (Count: 4)
*In-window utility destinations embedded inside Settings Center via `TransitionalBridgeContainer`:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Entry Point / Trigger | Ownership Domain |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 21 | **Personal Lyrics Library** | `PersonalLyricsLibraryView`<br>Bridge Router (`.library`) | `SpotifyLyrics/Views/Settings/PersonalLyricsLibraryView.swift`<br>`SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L3–662<br>L42–45 | • Settings Center -> `高级与数据` -> `打开我的歌词库` | Data & Tool Surface |
| 22 | **Listening History** | `ListeningHistoryView`<br>Bridge Router (`.history`) | `SpotifyLyrics/Views/Settings/ListeningHistoryView.swift`<br>`SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L3–82<br>L46–49 | • Settings Center -> `高级与数据` -> `查看最近播放` | Data & Tool Surface |
| 23 | **Listening Statistics** | `ListeningStatisticsView`<br>Bridge Router (`.statistics`) | `SpotifyLyrics/Views/Settings/ListeningStatisticsView.swift`<br>`SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L3–190<br>L50–53 | • Settings Center -> `高级与数据` -> `查看听歌统计` | Data & Tool Surface |
| 24 | **Experience Library** | `ExperienceLibrarySettingsView`<br>Bridge Router (`.experienceLibrary`) | `SpotifyLyrics/Views/Settings/ExperienceLibrarySettingsView.swift`<br>`SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L6–380<br>L54–57 | • Settings Center -> `高级与数据` -> `深入体验` -> `打开体验版本库` | Data & Tool Surface |

*(Supporting container implementation: `TransitionalBridgeContainer` in `SpotifyLyrics/Views/Settings/SettingsRootView.swift:L92-127`)*

### 2.6 Category 5: Unreachable Legacy Surfaces (Count: 1)
*Orphaned code surfaces preserved in tree but not in active production flow:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Current Status | Note |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 25 | **Lyrics Preferences Popover** | `LyricsPreferencesPopover` | `SpotifyLyrics/Views/Components/LyricsPreferencesPopover.swift` | L3–113 | **Dead Code** (0 callers across project) | Superseded by V3 Toolbar & Settings Center. Documented as Incidental. |

### 2.7 Category 6: Internal Debug Scenes & Sheets (Count: 5)
*Windows and sheets accessible only in `#if DEBUG` builds:*

| # | User-Facing Name | Swift Symbol | File Path | Line Range | Current Status |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 26 | **Presentation Preview Lab Window** | `Window(id: "presentation-preview-lab")`<br>`PresentationPreviewLabView` | `SpotifyLyrics/Main.swift`<br>`SpotifyLyrics/Views/Debug/PresentationPreviewLabView.swift` | L103–109<br>L7–303 | Internal Debug Window |
| 27 | **Direction D Preview Matrix Window** | `Window(id: "direction-d-preview-matrix")`<br>`DirectionDPreviewMatrixView` | `SpotifyLyrics/Main.swift`<br>`SpotifyLyrics/Views/Debug/DirectionDPreviewMatrixView.swift` | L111–115<br>L6–297 | Internal Debug Window |
| 28 | **Direction D Experimental Host Window** | `Window(id: "direction-d-experimental-host")`<br>`DirectionDExperimentalProductHost` | `SpotifyLyrics/Main.swift`<br>`SpotifyLyrics/Views/Components/DirectionD/DirectionDExperimentalProductHost.swift` | L117–122<br>L7–69 | Internal Debug Window |
| 29 | **Direction D Main Window** | `Window(id: "direction-d-main-window")`<br>`DirectionDMainWindowView`<br>`DirectionDMainWindowPresentationFactory` | `SpotifyLyrics/Main.swift`<br>`SpotifyLyrics/Views/Components/DirectionD/DirectionDMainWindowView.swift` | L90–101<br>L9–747<br>L748–770 | Internal Experimental Window |
| 30 | **Assist Explain Sheet** | `AssistExplainSheet` | `SpotifyLyrics/Views/Components/AssistExplainSheet.swift`<br>`SpotifyLyrics/Views/MainWindow/MainLyricsWindowView.swift` | L7–54<br>L81–94 | `#if DEBUG` Only Sheet |

### 2.8 Excluded Main Window Legacy Layouts (`EXCLUDED_MAIN_WINDOW_LEGACY_LAYOUTS`, Count: 1)
*Main window presentation implementations outside the secondary surface audit boundary:*

| # | Name | Swift Symbol | File Path | Line Range | Classification Rationale | Note |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| Excl-1 | **Immersive Split Window View** | `ImmersiveSplitWindowView` | `SpotifyLyrics/Views/MainWindow/ImmersiveSplitWindowView.swift` | L3–125 | **Main Window Legacy Layout** | 当前仍可经 Visual Tuning 手动选择；属于 Main Window legacy layout。因 audit contract 明确界定目标为“Main Window V3 与 Settings Center 之外的 secondary surfaces”，故排除在 secondary surface 总数之外。本轮不删除、不修、不设计。 |

---

## 3. Current Visual Language Audit

A side-by-side analysis reveals clear visual fragmentation across window classes:

### 3.1 Dimensions & Window Framing
1. **Auxiliary Panels**:
   - `FloatingLyricsPanel`: Restores user frame (default ~620x220, min 320x120, max 1400x800). Borderless, non-activating, resizable, floating level.
   - `CapsuleLyricsPanel`: Top-center pinned (collapsed 360x46, expanded 540x80, hover 420x58). Non-resizable, borderless, floating/statusBar level.
   - `FullScreenLyricsPanel`: Full screen frame (`screen.frame`), borderless, floating level, controls dynamically reveal/auto-hide.
2. **Standard Secondary Windows**:
   - `LyricsEditorWindowView`: Standalone SwiftUI `Window`, minWidth 980, minHeight 620, default 1100x720. Standard macOS window frame with native title bar and traffic lights, forcing dark scheme (`.preferredColorScheme(.dark)`).
3. **Popovers & Sheets**:
   - `SongSearchPopover`: Fixed 440x470.
   - `CurrentSongOperationsView`: Fixed width ~386, dynamic height (scrollable content).
   - `V3VisualTuningPopoverView`: Fixed width ~320, dynamic height.
   - `AlignmentPreviewView` sheet: minWidth 740, minHeight 520.
   - `LyricsVersionPickerView` sheet: 520x460.
   - `ReadingVersionEditorView` sheet: 560x460.
   - `MenuBarLyricsPopoverView`: Fixed width 280, height ~130.

### 3.2 Materials, Backgrounds & Chromes
- **V3 Main Window**: Dynamic multi-layer blurred artwork backdrop (`AppleMusicImmersiveV3BackdropView`) with translucent `.regularMaterial` pill toolbar.
- **Settings Center**: Native macOS `NavigationSplitView` with standard sidebar and Form backgrounds.
- **Floating Lyrics**: Transparent AppKit panel backing with customizable background tint/opacity (`floatingWindowOpacity` 0.45..1.0).
- **Top Capsule**: Pure black pill (`#000000` / dynamic island styling) with thin white stroke border (`Color.white.opacity(0.18)`).
- **Popovers**: macOS `.ultraThinMaterial` / native popover translucent background with dark appearance.
- **Lyrics Editor**: Pure solid dark background (`Color.black.opacity(...)` / standard dark window content) with standard `Divider()` lines, lacking the glass/material treatment found in V3 or Settings.
- **MenuBar Popover**: Dark capsule card with custom accent borders and native media button glyphs.

### 3.3 Header & Typography Inconsistencies
- **Settings Center**: Unified `PageHeaderView` (title 25pt rounded bold, subtitle 12pt regular secondary, icon pill).
- **Personal Lyrics Library**: Embedded custom header with `title2` font and search bar inline.
- **Listening History**: Custom header (`Text("最近播放").font(.system(size: 25, weight: .semibold, design: .rounded))`).
- **Listening Statistics**: Custom header (`Text("听歌统计").font(.system(size: 25, weight: .semibold, design: .rounded))`).
- **Lyrics Editor**: Custom HStack header with `.title3.weight(.semibold)` (18pt), subtitle `.subheadline` (14pt), and flat action buttons.
- **Alignment Preview Sheet**: Custom HStack with `.title3.weight(.semibold)` and caption subtitle.
- **Current Song Operations Popover**: Nested `TrackHeaderView` with title `.headline` and artist `.subheadline`.

---

## 4. Frozen Boundary Integrity Check

To ensure that the unification of other windows does not regress completed phases, we checked against frozen baselines:

| Frozen System Baseline | Boundary Rule | Secondary Surface Impact / Conflict Check |
| :--- | :--- | :--- |
| **V3 Visual Baseline**<br>(Ambient / Stage / Classic) | Background shaders, artwork presentation modes, soft lyric transition clock, and canvas typography are **strictly frozen**. | **No Conflict**: None of the secondary windows duplicate backdrop shaders. `V3VisualTuningPopoverView` directly edits V3 settings and belongs exclusively to V3. |
| **V3 Main Toolbar**<br>(Capsule floating bar) | Window mode menu, provider status, song ops, search, visual tuning, and settings buttons are **strictly frozen**. | **Verified**: Popovers anchor directly to toolbar buttons. Popover content must respect toolbar trigger contracts. |
| **Settings Center**<br>(5-category IA) | General, Lyrics & Text, Services & Sources, AI Translation, Advanced & Data are **strictly frozen**. | **Tension Identified**: `PersonalLyricsLibraryView`, `ListeningHistoryView`, and `ListeningStatisticsView` currently reside inside Settings -> Advanced & Data via `TransitionalBridgeContainer`. They are tool destinations, not settings panes. |
| **Presentation Clock** | Shared `PresentationClock` drives synchronized rendering across V3, Floating, Capsule, and FullScreen. | **No Conflict**: All presentation panels observe `PlaybackState.currentPlaybackPosition` via the same clock pipeline. |

---

## 5. Window-Level UX Problem Classification

We categorized all observed UX problems into four strict tiers:

### 5.1 Blocker (0 found)
*No blockers preventing app compilation, process startup, or basic window display.*

### 5.2 Relevant (Architecture, IA & Discoverability Issues)
1. **`LyricsEditorWindowView` Entry Point Obscurity & Window Management Deficit**:
   - `LyricsEditorWindowView` is defined as a top-level `Window("歌词编辑", id: "lyrics-editor")` in `Main.swift:L79-84`.
   - However, macOS system menus (`Window` or `File`) have **zero** menu items to open or focus it.
   - Users can only reach it via small buttons inside `CurrentSongOperationsView` popover ("编辑当前版本" / "空白歌词编辑器") or via Capsule expanded menu.
   - If the main window is closed or no song is playing, opening the editor is nearly impossible without opening the popover first.
2. **Transitional Bridge Incongruity in Settings Center**:
   - `PersonalLyricsLibraryView` (My Lyrics Library), `ListeningHistoryView` (Recent Plays), and `ListeningStatisticsView` (Listening Stats) are rich user data surfaces, not configuration settings.
   - In Settings Center, they are currently reached via `Section("实用工具")` in `Advanced & Data` and rendered inside `TransitionalBridgeContainer` with `< 返回高级与数据`.
   - This keeps Settings Center dirty and creates a modal push-back experience atypical for macOS preference windows.
3. **Inconsistent Auxiliary Window Interaction & State Synchronization**:
   - `FloatingLyricsPanel` supports `.interactive`, `.locked`, and `.passThrough` interaction modes.
   - `CapsuleLyricsPanel` supports collapsed, hover, and expanded states.
   - The status indicators and lock/unlock toggles for these modes are distributed inconsistently across the panels themselves, the toolbar menu, and Settings -> General.
4. **Visual Disconnection of `LyricsEditorWindowView` from V3 Design Tokens**:
   - The editor uses raw dark styling with generic system buttons (`Button("粘贴歌词")`, `Button("导入 TXT")`, etc.) in a cramped 12pt header.
   - It lacks the tokenized corner radii, unified button styles (`.borderedProminent`, `.controlBackground`), and card rhythm established in V3 and Settings Center.

### 5.3 Incidental (Minor Polish & Hygiene)
1. **Dead Code: `LyricsPreferencesPopover.swift`**:
   - 113 lines of unreferenced legacy code defining an old preferences popover (`LyricsPreferencesPopover.swift:L3-113`). Kept as documented Incidental finding, not deleted in this docs-only turn.
2. **Inconsistent Title Sizes across Modal Sheets**:
   - `AlignmentPreviewView` uses 18pt title3; `ReadingVersionEditorView` uses 18pt title3; `PersonalLyricsLibraryView` uses 22pt title2; `ListeningHistoryView` uses 25pt rounded title.
3. **Compact Mode Popover Anchor Shift**:
   - When the main window width is less than 880pt, the toolbar collapses into `compactMoreMenu`, which shifts the search and tuning popover anchor to a single "more" ellipsis button.

### 5.4 Speculative (Ignored / Not Addressed)
- Adding multi-window tiling support for secondary windows.
- Supporting arbitrary floating window geometry persistence across multiple dynamic external displays.

---

## 6. Runtime UI Sampling Evidence

Direct runtime sampling was performed against Debug builds with actual screenshots captured and saved to `99-System/attachments/`:

| Surface | Captured Artifact Path | Status & Visual Verification Findings |
| :--- | :--- | :--- |
| **Floating Lyrics** | `99-System/attachments/other_windows_audit_floating.png` | **PASS**: Transparent HUD panel, responsive font scaling, playback status bar, lock toggle reachable. |
| **Top Capsule** | `99-System/attachments/other_windows_audit_capsule.png` | **PASS**: Screen-top centered black pill, album artwork thumbnail, track title, current lyric line rendered cleanly. |
| **FullScreen Lyrics** | `99-System/attachments/other_windows_audit_fullscreen.png` | **PASS**: Full screen takeover with dynamic album art backdrop, oversized synced lyric rows, bottom auto-hiding controls. |
| **Song Search Popover** | `99-System/attachments/other_windows_audit_search.png` | **PASS**: Translucent popover with search field, Spotify authorization status pill, and catalog result state. |
| **Current Song Operations Popover** | `99-System/attachments/other_windows_audit_current_song_ops.png` | **PASS**: Popover anchored to `music.note.list`, displaying track metadata, LRCLIB source badge, primary lyrics action ("编辑当前版本"), display layer toggles, and reading section. |
| **V3 Visual Tuning Popover** | `99-System/attachments/other_windows_audit_visual_tuning.png` | **PASS**: Popover anchored to `rectangle.3.group`, providing backdrop blur presets (0%, 25%, 60%, 100%), artwork size presets, cover alignment, and layout switcher. |
| **Provider Status Indicator** | `99-System/attachments/other_windows_audit_provider_status.png` | **PASS**: Status dot indicator anchored in toolbar displaying active provider health. |
| **Personal Lyrics Library** | `99-System/attachments/other_windows_audit_library.png` | **PASS**: Transitional bridge destination in Settings displaying search input, sync folder selector, and asset inventory state. |
| **Listening History** | `99-System/attachments/other_windows_audit_history.png` | **PASS**: Transitional bridge destination in Settings displaying recent play logs with relative timestamps. |
| **Listening Statistics** | `99-System/attachments/other_windows_audit_statistics.png` | **PASS**: Transitional bridge destination in Settings displaying listening summary cards and top song/artist frequency lists. |
| **MenuBar Status Popover** | `99-System/attachments/other_windows_audit_menubar_popover.png` | **PASS**: Native status item popover displaying current track, current synced lyric line, playback transport controls, and "打开主窗口" button. |
| **Scrolled Advanced & Data (Tool Bridge Entries)** | `99-System/attachments/other_windows_audit_adv_scrolled.png` | **PASS**: Verifies reachability of "打开我的歌词库", "查看最近播放", "查看听歌统计", and "> 深入体验" within Settings Center. |

---

## 7. Special Question: What Does "Unify Other Windows" Actually Mean?

To prevent scope creep and maintain engineering discipline, the scope of "Other Windows Unification" is mapped into four distinct groups:

```
                      ┌───────────────────────────────────────────────┐
                      │    Other Windows Unification Classification   │
                      └───────────────────────┬───────────────────────┘
                                              │
         ┌──────────────────┬─────────────────┴─────────────────┬──────────────────┐
         ▼                  ▼                                   ▼                  ▼
    [Group A]          [Group B]                           [Group C]          [Group D]
  Freeze As-Is     Visual Language                     Ownership & Entry    Defer to Recovery
  (V3 Baseline /   (Dimensions, Materials,             (Window vs Popover,  (Catalog Search,
   Settings IA)     Headers, Card density)              Menu discoverability) Candidate E2E)
```

### Group A: Keep As-Is (Freeze Compliance)
*Surfaces that are already compliant with frozen contracts or belong exclusively to V3 / Settings Center baselines:*
1. **V3 Toolbar Popovers**: `V3VisualTuningPopoverView` and `providerStatusMenu` belong strictly to the V3 baseline and are frozen.
2. **Settings Center Sheets**: `TranslationPromptPreviewView` and `TranslationProfilesView` are native child sheets of Settings Center and are frozen.
3. **Auxiliary Core Presentation Clock**: The core synced line rendering and typography in `FloatingLyricsView`, `CapsuleLyricsView`, and `FullScreenLyricsView` are driven by the frozen presentation clock and need no algorithmic changes.

### Group B: Visual Language Convergence (Target for Design Contract)
*Surfaces that require visual, material, and typographic alignment:*
1. **`LyricsEditorWindowView` Chrome & Styling**:
   - Align window chrome, toolbar styling, and action button hierarchy with V3 design tokens (`LyricsDesignTokens`).
   - Replace flat custom buttons with standardized `.borderedProminent` / `.controlBackground` tokens.
   - Establish consistent padding, card background materials, and divider treatments.
2. **Embedded Tool Destinations (`ListeningHistoryView`, `ListeningStatisticsView`, `PersonalLyricsLibraryView`)**:
   - Standardize page headers to match the design language of `PageHeaderView`.
   - Align card corner radii (`LyricsDesignTokens.CornerRadius`), control density, and empty states.
3. **MenuBar Popover (`MenuBarLyricsPopoverView`)**:
   - Align button styling ("打开主窗口") and typography hierarchy with standard popover tokens.

### Group C: Ownership & Entry Point Convergence (Target for Design Contract)
*Surfaces requiring architectural decision on where they belong and how users discover them:*
1. **`LyricsEditorWindowView` Discoverability**:
   - Add standard macOS menu entries (e.g. `窗口 -> 歌词编辑器` or `编辑 -> 打开歌词编辑器`) so the window is discoverable independent of playback state.
2. **Tool Bridge Evolution**:
   - Clarify whether `PersonalLyricsLibraryView`, `ListeningHistoryView`, and `ListeningStatisticsView` permanently remain embedded inside Settings Center as utility views, or if they should have independent entry points / secondary window capabilities.
3. **Auxiliary Window Interaction Controls Synchronization**:
   - Ensure interaction states (lock, click-through, opacity) across Floating, Capsule, and FullScreen have predictable, synchronized toggles between Menu Bar, App Menu, and Toolbar.

### Group D: Defer to `Recovery / Search / Import E2E`
*Workflows and surfaces that belong to search, recovery, and candidate resolution are strictly out of scope:*
1. **`SongSearchPopover`**: Spotify Web API catalog query, authentication fallback, search debouncing, and search results list.
2. **`LyricsCandidatePreviewSheet` & `TranslationCandidatePreviewView`**: Candidate list selection, diffing, source rank scoring, and manual adoption.
3. **`PersonalLibraryImportPreviewSheet` & `PersonalDataImportPreviewSheet`**: JSON archive parsing, import conflict resolution, and database import transactions.
4. **`AlignmentPreviewView` & `AssistExplainSheet`**: Audio capture, segment alignment, speech recognition confidence display, and timestamp correction.
5. **Manual Import / Clipboard Parser Menus**: `prepareManualLyricsFromClipboard`, `prepareManualLyricsFromTXT`, and `prepareManualLyricsFromLRC`.

---

## 8. Important Deferral Boundary Declaration

> [!IMPORTANT]
> **Boundary Notice: `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`**
> The subsequent planned roadmap milestone following Other Windows Unification is **Recovery / Search / Import E2E**.
>
> Therefore:
> - Any modification to search indexing, search popover behavior, candidate preview sheets, manual import flows, alignment algorithms, or library database transactions is **strictly deferred**.
> - Other Windows Unification focuses strictly on **window lifecycle, visual language consistency, chrome styling, and menu discoverability**. It must NOT touch provider resolution or recovery logic.

---

## 9. Next Steps for Design Contract Phase

This audit completes the Read-Only Discovery phase. Before drafting implementation code, a formal **Design Contract** (`docs/superpowers/specs/2026-09-03-other-windows-unification-design.md`) should address the following decision points:

1. **Window Identity & Hierarchy Decision**:
   - Formalize `LyricsEditorWindowView` window level, minimum dimensions, and macOS App Menu entry points.
2. **Visual Token Adoption Plan**:
   - Define exact token mappings (`LyricsDesignTokens.Material`, `Spacing`, `CornerRadius`, `FontSize`) for `LyricsEditorWindowView`, `ListeningHistoryView`, and `ListeningStatisticsView`.
3. **Dead Code Retirement Plan**:
   - Authorize safe removal of unreferenced `LyricsPreferencesPopover.swift`.
4. **Tool Destination Architecture**:
   - Confirm retention of `TransitionalBridgeContainer` inside Settings while polishing internal view rhythm and headers.

---
*Audit Status: Ready for Final Review (`OTHER_WINDOWS_AUDIT_REVISION=READY_FOR_FINAL_REVIEW`)*

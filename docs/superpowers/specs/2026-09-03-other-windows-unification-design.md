# Other Windows & Secondary Surfaces Unification — Design Contract

- **Status**: Ready for Review
- **Date**: 2026-09-03
- **Branch Baseline**: `antigravity/other-windows-audit` (`origin/main = cc4230fc771997796a819233270de783dc37f16b`)
- **Document Path**: `docs/superpowers/specs/2026-09-03-other-windows-unification-design.md`
- **Audit Baseline**: `839f6b114bdcef1db7d1ecd5d04a79600e5cf724` (`docs/superpowers/audits/2026-09-03-other-windows-unification-audit.md`)

---

## 1. Context & Background

Following the successful completion and merge of Main Window V3 Composition, Main Toolbar, and Settings Center (PR #13, `cc4230f`), the product architecture now moves to the next planned milestone: **Other Windows & Secondary Surfaces Unification**.

A comprehensive Read-Only Audit (`d297b28`, `4f3ddc8`, `839f6b1`) completed an inventory of all 30 secondary surfaces across the application (24 user-reachable surfaces, 1 unreachable dead code popover, 5 `#if DEBUG` windows/sheets, plus 1 excluded main-window legacy layout).

This Design Contract defines the authoritative design decisions, visual token mappings, ownership boundaries, and candidate delivery sequence for secondary windows and auxiliary surfaces.

---

## 2. Audit Findings Carried Forward

The audit identified three major architectural and visual fragmentation areas:

1. **`LyricsEditorWindowView` Entry Point Obscurity & Window Management Deficit**:
   - Defined as a standalone window scene (`id: "lyrics-editor"`), but has **zero** presence in standard macOS menus (`Window` or `Edit`).
   - Highly coupled to the current playback state: users cannot discover or launch the editor if no song is playing or if the toolbar popover is closed.
2. **Settings Center Domain Violation for User Data Tools**:
   - `PersonalLyricsLibraryView` (Library), `ListeningHistoryView` (Recent Plays), and `ListeningStatisticsView` (Stats) are rich user data and activity surfaces, not configuration settings.
   - Currently accessed via `Section("实用工具")` in `Advanced & Data` and rendered inside `TransitionalBridgeContainer` with `< 返回高级与数据`. This preserves reachability but creates an atypical modal push-back experience.
3. **Visual Language & Interaction State Disconnection**:
   - `LyricsEditorWindowView` hardcodes a pitch-black background and flat buttons without tokenized materials.
   - Auxiliary window interaction states (locked, click-through, opacity, capsule expansion) are split between local panels, toolbar menus, and Settings General without unified semantic ownership.

---

## 3. Scope of Design

This contract strictly covers:

### Group B — Visual Language Convergence
1. `LyricsEditorWindowView`: Tokenized materials, unified header, action hierarchy, standard tool chrome.
2. `PersonalLyricsLibraryView`: Header rhythm, card density, tokenized empty states.
3. `ListeningHistoryView`: Header standardization, list rhythm, relative timestamp formatting tokens.
4. `ListeningStatisticsView`: Header standardization, card corner radii, metric summaries.
5. `MenuBarLyricsPopoverView`: Typography hierarchy, transport buttons, and bottom action styling.

### Group C — Ownership & Entry Convergence
1. `LyricsEditorWindowView`: Global discovery via standard macOS `Window` menu + blank/no-track initialization.
2. `Library / History / Statistics`: Long-term ownership decision (Option B: Unified Tool Window + Settings Bridge launcher).
3. `Floating / Capsule / FullScreen`: Canonical ownership rule for local vs toolbar vs settings interaction controls.

---

## 4. Explicit Frozen / No-Go (Strict Invariants)

The following core modules and subsystems are **strictly frozen** and must not be redesigned or altered:

- **Main Window V3 Visual Baseline**: Ambient, Stage, and Classic presentation modes, dynamic artwork backdrop shaders, Soft Lyric Transition clock, canvas typography.
- **V3 Main Toolbar**: Floating capsule layout, `compactMoreMenu` breakpoints, visual tuning popover, and toolbar trigger contracts.
- **Provider Status Indicator**: Status dot indicator and recovery dropdown menu.
- **Current Song Operations Popover**: Popover ownership, primary track header, and reading generation controls.
- **Settings Center Information Architecture**: 5-category primary IA (General, Lyrics & Text, Services & Sources, AI Translation, Advanced & Data).
- **PresentationClock & Soft Transition Engine**: Shared clock synchronization across all presentation targets.
- **Underlying Engines & Providers**: Playback pipeline, network providers, Keychain credentials, SQLite schemas.

---

## 5. Explicit Deferrals (`DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E`)

The following surfaces, sheets, and logic belong to the upcoming **Recovery / Search / Import E2E** milestone and are strictly out of scope:

| Deferred Surface / Workflow | Deferral Tag | Reason |
| :--- | :--- | :--- |
| `SongSearchPopover` workflow | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Spotify Web API query, debouncing, OAuth fallback. |
| `LyricsCandidatePreviewSheet` | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Candidate resolution scoring, diffing, adoption. |
| `TranslationCandidatePreviewView` | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Multi-candidate translation diff and selection. |
| `PersonalLibraryImportPreviewSheet` | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Folder scan, LRC/TXT parsing, import transactions. |
| `PersonalDataImportPreviewSheet` | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | JSON archive deserialization, conflict resolution. |
| `AlignmentPreviewView` | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Audio capture, speech confidence, timestamp alignment. |
| `AssistExplainSheet` (`#if DEBUG`) | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Audio capture permissions, experimental aligner. |
| Manual clipboard / TXT / LRC parser logic | `DEFER_TO_RECOVERY_SEARCH_IMPORT_E2E` | Core parsing and regex timestamp extraction. |

---

## 6. Lyrics Editor — Design Contract

### 6.1 Window Identity
`Lyrics Editor` is an **independent macOS productivity tool window**.
- It is NOT a Settings pane.
- It is NOT a modal sheet.
- It is NOT a presentation layout of the main window.

### 6.2 Global Window Entry & Menu Placement
- **Decision**: Place the global entry in the **`Window` menu** (`窗口 -> 歌词编辑器` / `Window -> Lyrics Editor`, keyboard shortcut `Cmd+Shift+E`).
- **Rationale**:
  1. *macOS HIG Standard*: The `Window` menu is the canonical location for opening, focusing, and cycling auxiliary productivity windows (e.g., Xcode Organizer, Music.app MiniPlayer, Terminal Inspector).
  2. *Single Discovery Paradigm*: In Spotify Lyrics, all secondary presentation windows already live in the `Window` menu (`Cmd+1` for Main Window, `Cmd+Opt+F` for Floating, `Cmd+Opt+C` for Capsule, `Cmd+Opt+G` for FullScreen). Placing the Editor in `Window` consolidates all openable windows into one familiar place.
  3. *Edit Menu Inappropriateness*: The `Edit` menu is reserved for in-place text clipboard and undo operations (`Undo`, `Redo`, `Cut`, `Copy`, `Paste`, `Select All`). Spawning an entire window from `Edit` violates macOS platform conventions.
- **Preserved Existing Triggers**:
  - `CurrentSongOperationsView`: "编辑当前版本" button (loads active song's lyrics) and "创建空白歌词" / "空白歌词编辑器".
  - `CapsuleLyricsView`: "编辑歌词" context menu item.

### 6.3 Empty & No Current Track Behavior
- When launched via `Window` menu or shortcut:
  - **Song Playing with Lyrics**: Automatically binds to current track and active `LyricsVersion`.
  - **Song Playing without Lyrics**: Opens with current track metadata pre-filled and an empty lyrics editor canvas.
  - **No Song Playing**: Opens in **Blank Editor State** with empty title, blank artist, and editable scratchpad. The window **MUST NEVER** be blocked from opening due to inactive Spotify playback.

### 6.4 Window Geometry
- **Window Type**: Standard macOS titled window with native title bar, close/minimize/zoom traffic lights, and unified toolbar (`.windowToolbarStyle(.unified)`).
- **Default Size**: `1100 x 720` pt.
- **Minimum Size**: `980 x 620` pt.
- **Resizable**: Fully resizable with proportional split between editor timeline and metadata/preview columns.
- **Strict Prohibition**: Do NOT convert to a borderless HUD panel.

### 6.5 Visual Language & Styling
- **Design Baseline**: Clean macOS productivity tool styled with `LyricsDesignTokens`.
- **Background**: Subtle dark environment layer (`Color(nsColor: .windowBackgroundColor)` / `LyricsDesignTokens.Material.darkBase`), avoiding flat pitch black (`#000000`).
- **Contrast & Legibility**: Strict readability priority. Timestamps use `DesignTokens.Font.monospaced` for tabular alignment.
- **Prohibitions**:
  - No giant artwork ambient blur shaders in the editor background.
  - No oversized glowing cards or animated background elements that compete with text editing.

### 6.6 Header & Action Hierarchy
- **Header Layout**: Compact, single-row tool header (height ~48pt):
  - **Leading**: Window title `Text("歌词编辑").font(.headline.weight(.semibold))` + current track badge (or `Text("空白草稿").font(.caption).foregroundStyle(.secondary)`).
  - **Center**: Status indicator (e.g., "已修改未保存" / "已同步当前播放").
  - **Trailing Action Hierarchy**:
    - *Primary Action*: 保留现有真实保存/应用行为，统一采用 `.buttonStyle(.borderedProminent)` 样式。准确按钮文案与是否存在 detached/local-save 分支由 Implementation Plan 根据源码审计后确定；Design Contract 不得新增新的保存模型或数据语义。`Cmd+S` 仅在源码现有保存行为可安全映射时才允许在 Implementation Plan 中采用。
    - *Secondary Actions*: `Button("粘贴歌词")`, `Button("导入…")` (menu for TXT/LRC), `Button("重置")`.
    - *Destructive Actions*: None added.

---

## 7. Library / History / Statistics — Ownership Decision

### 7.1 Authoritative Ownership Model: Option B
- **Decision**: **Option B — Upgrade to a Unified Tool Window, retaining Settings Bridge as a Quick Launcher**.
- **Unified Tool Window Identity**:
  - Declare a single standalone window scene:
    `Window("歌词库与收听记录", id: "personal-library-activity")`
  - Default size: `920 x 600` pt; Minimum size: `800 x 500` pt.
  - Menu Entry: `窗口 -> 歌词库与收听记录` (`Cmd+Opt+L`).
- **Internal Tab Architecture**:
  The window contains three segmented sections:
  1. **我的歌词库 (`My Lyrics Library`)**: The full `PersonalLyricsLibraryView` with search, sync folders, and asset version inspector.
  2. **最近播放 (`Listening History`)**: The `ListeningHistoryView` displaying sequential play logs with relative timestamps.
  3. **听歌统计 (`Listening Statistics`)**: The `ListeningStatisticsView` displaying summary cards and frequency charts.
- **Settings Center Bridge Retention**:
  - In `Settings -> Advanced & Data -> Section("实用工具")`:
    - `Button("打开我的歌词库")` -> Opens `personal-library-activity` and selects tab `.library`.
    - `Button("查看最近播放")` -> Opens `personal-library-activity` and selects tab `.history`.
    - `Button("查看听歌统计")` -> Opens `personal-library-activity` and selects tab `.statistics`.
  - In-window `TransitionalBridgeContainer` push-back navigation inside Settings is gracefully superseded by opening the dedicated window, completely eliminating Settings Center modal clipping and cognitive nesting.

### 7.2 Experience Library Boundary
- `ExperienceLibrarySettingsView` **REMAINS** in `Settings -> Advanced & Data -> 深入体验`.
- It is NOT moved to the user tool window because it manages experimental mocks, internal presentation previews, and test environments intended for developer/power-user diagnosis.

---

## 8. Embedded Tool Visual Contract

For all tool views (`PersonalLyricsLibraryView`, `ListeningHistoryView`, `ListeningStatisticsView`):

| Design Attribute | Specification | Design Token |
| :--- | :--- | :--- |
| **Top Padding** | Standardized `20pt` below window toolbar / tab bar. | `LyricsDesignTokens.Spacing.l` |
| **Horizontal Padding** | `24pt` safe content margin. | `LyricsDesignTokens.Spacing.xl` |
| **Header Typography** | Title: `20pt semibold rounded`; Subtitle: `12pt regular secondary`. | `PageHeaderView` compact variant |
| **Section Spacing** | `16pt` vertical gap between groups. | `LyricsDesignTokens.Spacing.m` |
| **Card Corner Radius** | `10pt` for metric containers, `8pt` for inner rows. | `LyricsDesignTokens.CornerRadius.card` |
| **Card Background** | `Color(nsColor: .controlBackgroundColor)` or `.regularMaterial`. | Native macOS card tokens |
| **Empty States** | Standardized icon (40pt secondary) + headline (14pt semibold) + caption (12pt). | Unified Empty State pattern |
| **Data Integrity** | Zero schema, query, or ViewModel modifications. | Read-only presentation binding |

---

## 9. MenuBar Popover Contract

### 9.1 Functional Role
The MenuBar Popover is strictly for **Quick Glance + Quick Transport**. It is NOT a mini main window.

### 9.2 Geometry & Materials
- **Dimensions**: Fixed width `280pt`, auto-height bounded between `120pt` and `150pt`.
- **Corner Radius**: `12pt` continuous rounded rect.
- **Material**: macOS `.ultraThinMaterial` / native popover vibrancy.

### 9.3 Content Layout & Typography
1. **Track Header**:
   - Leading album art thumbnail (`32x32`, corner radius 6pt).
   - Track Title: `13pt bold`, max 1 line with middle truncation.
   - Artist Name: `11pt secondary`, max 1 line with tail truncation.
2. **Lyric Glance Area**:
   - Active synced lyric line: `13pt semibold`, primary color, max 2 lines.
   - Empty/Paused/No-lyrics states: clean 12pt secondary message.
3. **Transport & Bottom Actions**:
   - Media transport: `backward.fill` (12pt), `play.fill` / `pause.fill` (14pt), `forward.fill` (12pt).
   - Bottom Trailing Action: `Button("打开主窗口")` (`.buttonStyle(.borderless)` or `.borderedProminent` compact).

### 9.4 Explicit Prohibitions
- NO next-line lyrics preview.
- NO search field or search results.
- NO preferences or settings shortcuts.
- NO provider switching or audio routing controls.
- NO visual tuning backdrop controls.

---

## 10. Auxiliary Window Interaction Controls Ownership

To eliminate contradictory settings across panels, toolbar, and preferences, interaction controls are partitioned into three non-overlapping tiers:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Interaction Control Ownership Hierarchy               │
├───────────────────────────┬─────────────────────────────────────────────────┤
│ Tier 1: Surface-Local     │ Immediate, transient state (hover lock button,  │
│         Ephemeral Control │ hover expansion, mouse-move control fade).      │
├───────────────────────────┼─────────────────────────────────────────────────┤
│ Tier 2: Toolbar           │ Global presentation visibility (show/hide/switch│
│         Window Mode Menu  │ between Main V3, Floating, Capsule, FullScreen).│
├───────────────────────────┼─────────────────────────────────────────────────┤
│ Tier 3: Settings General  │ Persistent user defaults (launch auto-open,     │
│         Configuration     │ saved window geometry, default opacity).        │
└───────────────────────────┴─────────────────────────────────────────────────┘
```

### 10.1 Rules
1. **Toolbar `Window Mode Menu`**:
   - ONLY handles **Show / Hide / Switch** of presentation targets (`Floating`, `Capsule`, `FullScreen`, `Main Window`).
   - Does NOT house opacity sliders, click-through toggles, or alignment configuration.
2. **Settings `General`**:
   - Houses **persistent defaults**: "启动时恢复上次窗口状态", "悬浮歌词保持置顶", "默认交互状态 (可编辑 / 可拖动 vs 穿透)", "悬浮窗默认透明度".
3. **Surface Local Panels**:
   - Manage **immediate transient interaction**:
     - *Floating*: Local hover lock icon directly toggles `.locked` / `.interactive`.
     - *Capsule*: Local hover dynamically expands pill to show track & progress.
     - *FullScreen*: Cursor movement dynamically reveals overlay; 3s idle auto-fades.

---

## 11. Dead Code Hygiene

- **Target**: `SpotifyLyrics/Views/Components/LyricsPreferencesPopover.swift` (L3–113).
- **Classification**: `Incidental cleanup candidate`.
- **Policy**: This file has 0 callers across the repository. It is noted in documentation for future cleanup, but will **NOT** be modified or deleted during the active candidates of this phase to avoid scope expansion.

---

## 12. Accessibility (a11y)

- **VoiceOver**: All tool buttons across Editor, Tool Window, and MenuBar must have explicit `.accessibilityLabel` and `.accessibilityHint` (e.g., "保存歌词", "切换至歌词库", "播放或暂停").
- **Keyboard Navigation**:
  - Full tab loop across Lyrics Editor timeline rows and action buttons.
  - Standard keyboard shortcuts: `Cmd+Shift+E` (Editor), `Cmd+Opt+L` (Library & Activity). 编辑器文本输入必须严格保留标准 Space 键输入行为，严禁占用 Space 键作为播控快捷键。
- **Reduce Motion**: Inherits existing `@Environment(\.accessibilityReduceMotion)` behavior and preserves already-frozen presentation behavior. No new animation timing constants and no new motion system are introduced.

---

## 13. Window Sizing & Responsive Matrix

| Surface | Min Dimensions | Default Dimensions | Wide Behavior | Compact Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Lyrics Editor** | 980 x 620 | 1100 x 720 | Metadata column fixed 320pt; editor timeline expands. | Metadata column collapses into inspector tab. |
| **Library & Activity** | 800 x 500 | 920 x 600 | Master-detail split expands asset details list. | Sidebar collapses; table switches to single column. |
| **Floating Lyrics** | 320 x 120 | 620 x 220 | Text scale adapts dynamically (font size bounds). | Single-line mode, min padding. |
| **Top Capsule** | 360 x 46 (docked) | 540 x 80 (expanded)| Extends width up to 600pt for long titles. | Truncates title with ellipsis. |
| **FullScreen Lyrics** | Screen Bounds | Screen Bounds | Center column maxWidth 900pt; backdrop covers. | Full-width responsive text scaling. |
| **MenuBar Popover** | 280 x 120 | 280 x 135 | Fixed width (280pt). | Fixed width (280pt). |

---

## 14. Candidate Delivery Sequence

To ensure atomic, reviewable increments, the work is organized into 5 sequential Candidates:

```
[Candidate 1: P0] Lyrics Editor Visual Convergence
       │
       ▼
[Candidate 2: P0] Lyrics Editor Window Entry & No-Track State
       │
       ▼
[Candidate 3: P1] Library & Activity Unified Tool Window & Entry
       │
       ▼
[Candidate 4: P1] Embedded Tool Views Visual Convergence
       │
       ▼
[Candidate 5: P2] MenuBar Popover & Interaction Consistency
```

---

## 15. Candidate Acceptance Criteria

### Candidate 1 (P0): Lyrics Editor Visual Convergence
- **Scope**: Re-skin `LyricsEditorWindowView` using `LyricsDesignTokens`. Establish compact tool header, tokenized material background, and distinct primary action hierarchy.
- **Allowed Files**: `SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift`.
- **Forbidden Files**: Any provider, parser, database, or settings file.
- **Runtime Acceptance**: Editor displays modern macOS tool styling with `.regularMaterial` / tokenized background, legible monospace timestamps, and clear `.borderedProminent` save button.
- **Screenshots**: `other_windows_c1_editor_visual.png`.
- **Stop Condition**: Visual styling complete; stop before adding menu commands.

### Candidate 2 (P0): Lyrics Editor Menu Discoverability & Empty State
- **Scope**: Add `窗口 -> 歌词编辑器` (`Cmd+Shift+E`) to main macOS app menu. Support launching editor when no song is playing (Blank Editor mode).
- **Allowed Files**: `SpotifyLyrics/Main.swift`, `SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift`.
- **Forbidden Files**: Provider, parser, network, or V3 main window files.
- **Runtime Acceptance**: User can open editor via `Cmd+Shift+E` with or without Spotify running. With track: loads track; without track: loads clean blank canvas.
- **Screenshots**: `other_windows_c2_editor_menu.png`, `other_windows_c2_editor_empty.png`.
- **Stop Condition**: Menu item and empty state working; stop before creating Library window.

### Candidate 3 (P1): Library & Activity Unified Tool Window & Entry
- **Scope**: Declare standalone `Window("歌词库与收听记录", id: "personal-library-activity")` with 3 segmented tabs. Add `窗口 -> 歌词库与收听记录` (`Cmd+Opt+L`). Update Settings `Section("实用工具")` buttons to launch this window and select corresponding tabs.
- **Allowed Files**: `SpotifyLyrics/Main.swift`, `SpotifyLyrics/Views/Settings/SettingsRootView.swift`, new container view for tool window.
- **Forbidden Files**: Database models, migration scripts, V3 canvas.
- **Runtime Acceptance**: Window opens independently via shortcut or Settings bridge, seamlessly switching between Library, History, and Statistics.
- **Screenshots**: `other_windows_c3_tool_window_tabs.png`, `other_windows_c3_settings_bridge_launch.png`.
- **Stop Condition**: Window lifecycle and tab switching verified; stop before visual token refactoring of inner views.

### Candidate 4 (P1): Embedded Tool Views Visual Convergence
- **Scope**: Standardize header hierarchy, card corner radii, margins, and empty states in `PersonalLyricsLibraryView`, `ListeningHistoryView`, and `ListeningStatisticsView`.
- **Allowed Files**: `SpotifyLyrics/Views/Settings/PersonalLyricsLibraryView.swift`, `ListeningHistoryView.swift`, `ListeningStatisticsView.swift`.
- **Forbidden Files**: SQLite storage, sync logic, parser logic.
- **Runtime Acceptance**: All three tool views exhibit unified 20pt rounded headers, clean card styling, and consistent empty-state typography.
- **Screenshots**: `other_windows_c4_library_visual.png`, `other_windows_c4_history_visual.png`, `other_windows_c4_statistics_visual.png`.
- **Stop Condition**: Inner views visually converged; stop before MenuBar adjustments.

### Candidate 5 (P2): MenuBar Popover & Auxiliary Interaction Consistency
- **Scope**: Align `MenuBarLyricsPopoverView` typography and button styling with popover design tokens. Clarify Floating/Capsule local hover lock/expansion states.
- **Allowed Files**: `SpotifyLyrics/Views/MenuBar/MenuBarLyricsPopoverView.swift`, `SpotifyLyrics/Views/Floating/FloatingLyricsView.swift`, `SpotifyLyrics/Views/Capsule/CapsuleLyricsView.swift`.
- **Forbidden Files**: Audio playback engine, status item lifecycle.
- **Runtime Acceptance**: MenuBar popover displays polished 280pt card with clear transport buttons. Floating and Capsule local hover controls operate predictably without conflicting with Settings defaults.
- **Screenshots**: `other_windows_c5_menubar_popover.png`, `other_windows_c5_floating_controls.png`.
- **Stop Condition**: All 5 candidates complete; ready for Final Integration Review.

---

## 16. Verification Plan

1. **Static Checks**:
   - `git diff --check origin/main...HEAD` must pass with 0 warnings.
   - Zero Swift source changes during design contract phase.
2. **Xcode Debug Build**:
   - `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/spotifylyrics-other-windows-dd build` must succeed (`** BUILD SUCCEEDED **`).
3. **Boundary Check**:
   - Confirm zero regression on V3 toolbar, V3 backdrop composition, and Settings Center 5-category layout.

---
*Design Contract Status: Ready for Review (`OTHER_WINDOWS_DESIGN=READY_FOR_REVIEW`)*

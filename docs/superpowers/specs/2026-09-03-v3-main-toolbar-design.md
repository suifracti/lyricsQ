# V3 Main Window Top-Right Toolbar Convergence Design Contract

**Document Status**: Design Contract
**Branch**: `antigravity/v3-toolbar-design`
**Base Commit**: `7df89eb4dc0ba2d91404c18823db3bf6b037f907`
**Implementation Target**: V3 Main Window Toolbar (Top-Right Capsule)

---

## 1. Toolbar Role & Architectural Boundary

### 1.1 Toolbar Role
The V3 Main Window Top-Right Toolbar is a **lightweight, restrained utility rail** designed to provide instant access to window modes, current song lyrics operations, search, and essential presentation tuning without competing with the primary listening and reading canvas.

It belongs strictly to the **Interactive Layer** of the Spotify Lyrics visual hierarchy:
- It is **not** a persistent dashboard card or heavy panel;
- It must **never** compete with the artwork as the visual subject (Stage) or with the parallel reading column (Classic/Ambient);
- It must recede naturally when the user is simply listening and reading.

---

## 2. Information Architecture & Action Inventory

### 2.1 Current Action Audit

| Action | Current Trigger | Implementation | Nature | Redundancy / Issue |
| :--- | :--- | :--- | :--- | :--- |
| **Window Mode** | `rectangle.on.rectangle` | `Menu` | Presentation / Window | Switch to Floating, Capsule, Fullscreen; clean. |
| **Provider Status** | Colored dot (`Circle`) | `Menu` | Status + Kitchen Sink | Conflates connection indicator with duplicated workflows (versions, translation, alignment). |
| **Current Song Operations** | `music.note.list` | Popover (`CurrentSongOperationsView`) | Song Operations | Rich in-place lyrics management (versions, translation, furigana, alignment). |
| **Song Search** | `magnifyingglass` | Popover (`SongSearchPopover`) | Contextual / Search | Manual track/lyrics search and matching; clean. |
| **Visual Tuning** | `rectangle.3.group` | Popover (`V3VisualTuningPopoverView`) | Presentation Tuning | Ambient/Stage/Classic mode, blur, artwork scale, position; clean. |
| **Preferences** | `gearshape` | `SettingsLink` | Global Settings | Opens macOS Settings; default styling introduces mismatched button chrome. |

### 2.2 Action Categorization

- **Category A: Primary Window Actions (In-session, frequent/direct)**
  - Window Mode (`rectangle.on.rectangle`): switch projection (Floating / Capsule / Fullscreen).
  - Search (`magnifyingglass`): find and correct lyrics when auto-matching is inaccurate.
  - Song Lyrics Operations (`music.note.list`): single unified surface for lyrics versions, translation, furigana/reading, and alignment.
- **Category B: Presentation Tuning (Session-level layout preference)**
  - Visual Tuning (`rectangle.3.group`): composition mode (Ambient / Stage / Classic), blur scale, artwork scale.
- **Category C: Secondary / Configuration (Low-frequency, system-level)**
  - Global Settings (`gearshape`): macOS system preferences.
  - Provider Status: pure status indicator & reconnection trigger, not a duplicate operations container.
- **Category D: Contextual Operations**
  - Translation, alignment, version selection: owned solely by `CurrentSongOperationsView` and not duplicated inside the status dot.

---

## 3. Convergence Contract

### 3.1 De-duplication & Separation of Concerns
1. **Provider Status Contract**:
   - The status indicator represents **Spotify playback connection & provider health**;
   - It must **not** duplicate lyrics version lists, translation controls, or alignment workflows already housed in `CurrentSongOperationsView`;
   - Its scope is restricted to:
     - Displaying provider / playback health status;
     - Retaining existing and necessary recovery / retry operations (e.g. Spotify reconnection, Mock Preview toggling).
2. **Current Song Operations Contract**:
   - `music.note.list` remains the **single authoritative entry point** for all per-track lyrics operations (versions, translations, ruby/furigana, audio-lyrics alignment).

### 3.2 Visual Styling & Chrome Uniformity
1. **Unified Action Language**:
   - Action items within the toolbar must share a consistent visual language with sufficient and mutually consistent interaction targets;
   - The Preferences action (`gearshape`) must unify its presentation with the rest of the toolbar actions, eliminating mismatched system button backgrounds or borders.
2. **Pressed & Hover States**:
   - Conforms strictly to the approved Visual Baseline: subtle hover brightening, restrained 0.96 pressed scale under normal motion, and 1.0 scale under Reduce Motion; no exaggerated spring oscillations.

---

## 4. Responsive & Adaptive Convergence

### 4.1 Compact Strategy (< 800pt width or < 600pt height)
- **Problem**: In Compact windows (e.g. 760×520), an unconstrained action rail crowds the centered album block and reading space.
- **Priority Rules**:
  - Compact must reduce the number of permanently visible actions;
  - Window Mode and Current Song Operations have the highest priority for persistent visibility;
  - Other lower-frequency actions can enter a secondary / overflow surface;
  - The toolbar must not compete with the artwork or lyrics for primary reading space;
  - Specific secondary surface presentation (e.g. menu vs popover) is left to the implementation plan.

### 4.2 Standard & Wide Strategy (≥ 900pt width, ≥ 600pt height)
- Standard and Wide provide ample horizontal space;
- Retains primary actions directly visible while avoiding runaway button growth;
- Upper lyrics lines scroll behind/beside the toolbar; the material background ensures legibility over both dark and vibrant artwork.

### 4.3 Mode Consistency (Ambient / Stage / Classic)
- The toolbar information architecture and interaction rules are **100% identical** across Ambient, Stage, and Classic;
- No mode-specific button insertion or deletion is permitted;
- Contextual differences (e.g. Stage having no foreground cover) must not alter the toolbar's position or action set.

---

## 5. Visibility & Keep-Alive Contract

### 5.1 Hover Sensor & Reveal
- Retain existing hover reveal zone and idle auto-hide semantics;
- Transition respects existing motion tokens with immediate or short response under Reduce Motion.

### 5.2 Popover Keep-Alive Contract
- **Keep-Alive Requirement**: When any toolbar-associated secondary surface, popover, or menu is presented (including Visual Tuning, Search, and Current Song Operations), the toolbar must remain visible and interactive throughout the interaction, and must not automatically disappear while the user is engaging with the surface.

---

## 6. Accessibility & Keyboard Contract

1. **Accessible Names**: Every icon-only action must have an understandable accessible name using the project's existing language and localization capabilities (without introducing new localization infrastructure in this round).
2. **Keyboard Focus & Tab Navigation**:
   - All toolbar actions must be navigable via Tab / Shift-Tab;
   - Active focus ring must render visibly and cleanly without clipping.
3. **No Hover Dependency for Accessibility**:
   - Screen readers (VoiceOver) and Full Keyboard Access must be able to focus and activate toolbar actions regardless of pointer hover state.
4. **Reduce Motion**:
   - Zero scale changes on hover or pressed states;
   - Transitions respect existing Reduce Motion timing.

---

## 7. Explicit No-Go Boundaries

This Toolbar Convergence design strictly forbids:
- Redesigning the Settings Window / Center;
- Redesigning the Fullscreen or Floating lyrics windows;
- Redesigning the Top Capsule lyrics presentation;
- Redesigning the playback transport controls or playback progress bar;
- Redesigning the search algorithm, lyrics provider, or network fetch architecture;
- Modifying background blur algorithms, palette extraction, or `normalizedBlur`;
- Modifying Stage, Classic, or Ambient composition layouts;
- Modifying the Presentation Clock, lyric synchronization, or soft transitions;
- Modifying database schemas or user settings keys.

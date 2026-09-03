# V3 Main Window Top-Right Toolbar Convergence Design Contract

**Document Status**: Approved Design Contract Draft  
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
| **Provider Status** | 8pt colored dot (`Circle`) | `Menu` | Status + Kitchen Sink | Conflates connection indicator with 20+ duplicated actions (versions, translation, alignment). |
| **Current Song Operations** | `music.note.list` | Popover (`CurrentSongOperationsView`) | Song Operations | Rich in-place lyrics management (versions, translation, furigana, alignment). |
| **Song Search** | `magnifyingglass` | Popover (`SongSearchPopover`) | Contextual / Search | Manual track/lyrics search and matching; clean. |
| **Visual Tuning** | `rectangle.3.group` | Popover (`V3VisualTuningPopoverView`) | Presentation Tuning | Ambient/Stage/Classic mode, blur, artwork scale, position; clean. |
| **Preferences** | `gearshape` | `SettingsLink` | Global Settings | Opens macOS Settings; default styling introduces mismatched gray button chrome. |

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
1. **Provider Status Dot Contract**:
   - The status dot (`Circle`) represents **Spotify playback connection & provider health**;
   - It must **not** duplicate the full lyrics version list, translation controls, or alignment workflows already housed in `CurrentSongOperationsView`;
   - Its menu is restricted to:
     - Provider connection status message;
     - Spotify reconnect / Mock Preview toggle;
     - Direct jump to lyrics editor (if available).
2. **Current Song Operations Contract**:
   - `music.note.list` remains the **single authoritative entry point** for all per-track lyrics operations (versions, translations, ruby/furigana, audio-lyrics alignment).

### 3.2 Visual Styling & Chrome Uniformity
1. **Capsule Uniformity**:
   - All action items within the toolbar capsule must share the same icon button presentation (borderless, 32×32pt interaction target, 15pt SF Symbol, `white.opacity(0.82)` idle foreground);
   - `SettingsLink` (`gearshape`) must not inherit macOS default button borders, backgrounds, or dark gray rounded rectangles; it must conform strictly to the standard toolbar icon style.
2. **Pressed & Hover States**:
   - Conforms strictly to the approved Visual Baseline: subtle hover brightening, 0.96 pressed scale under normal motion, 1.0 scale under Reduce Motion; no heavy spring oscillations.

---

## 4. Responsive & Adaptive Convergence

### 4.1 Compact Strategy (< 800pt width or < 600pt height)
- **Problem**: In 760×520, a 6-button capsule spans ~260pt and approaches within ~20pt of the centered album artwork.
- **Convergence Rule**:
  - Priority Visible in Compact:
    1. Window Mode (`rectangle.on.rectangle`)
    2. Song Lyrics Operations (`music.note.list`)
    3. Overflow / More (`ellipsis.circle` or unified secondary entry)
  - Actions eligible to move into Overflow during Compact:
    - Visual Tuning (`rectangle.3.group`)
    - Global Settings (`gearshape`)
    - Search (`magnifyingglass`)
  - **Hard Requirement**: Toolbar must never overlap or crowd the centered album block or top window controls.

### 4.2 Standard & Wide Strategy (≥ 900pt width, ≥ 600pt height)
- Standard and Wide provide ample horizontal space;
- Retains primary actions directly visible while avoiding runaway button growth (maximum 5–6 items in capsule);
- Upper lyrics lines scroll behind/beside the toolbar; the material background (`.regularMaterial`) ensures legibility over both dark and vibrant artwork.

### 4.3 Mode Consistency (Ambient / Stage / Classic)
- The toolbar information architecture and interaction rules are **100% identical** across Ambient, Stage, and Classic;
- No mode-specific button insertion or deletion is permitted;
- Contextual differences (e.g. Stage having no foreground cover) must not alter the toolbar's position or action set.

---

## 5. Visibility, Hover & Popover Contract

### 5.1 Hover Sensor & Reveal
- Reveal trigger zone: top 96pt of the window (`location.y <= 96`);
- Idle auto-hide delay: 3.0 seconds after pointer inactivity;
- Transition: 0.18s–0.24s smooth opacity fade; immediate in Reduce Motion.

### 5.2 Popover Keep-Alive Contract (Bug Fix Requirement)
- **Current Bug**: Only `isVisualTuningPresented` suppresses auto-hide; opening Search or Current Song Operations causes the toolbar to fade out if the pointer drifts outside the 96pt zone.
- **Contract**: The toolbar **must remain visible and interactive** whenever **any** associated popover or menu is presented:
  ```
  toolbarKeptVisible = toolsVisible 
      || isVisualTuningPresented 
      || isSearchPresented 
      || isCurrentSongOperationsPresented
  ```

---

## 6. Accessibility & Keyboard Contract

1. **Accessible Names**: Every icon button must have an explicit, descriptive `.accessibilityLabel` in Chinese matching user language settings.
2. **Keyboard Focus & Tab Navigation**:
   - All toolbar buttons must be navigable via Tab / Shift-Tab;
   - Active focus ring must render cleanly without clipping within the capsule.
3. **No Hover Dependency for Accessibility**:
   - Screen readers (VoiceOver) and Full Keyboard Access must be able to focus and activate toolbar actions regardless of pointer hover state.
4. **Reduce Motion**:
   - Zero scale changes on hover or pressed states;
   - Toolbar fade transitions snap to immediate or short (~0.12s) opacity.

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

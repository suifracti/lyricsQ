# Three-style restoration evidence

> Stage definition superseded by the user on 2026-09-05: cover fills the whole background and lyrics overlay it. The separate cover-plane/read-zone results below are historical, not the current accepted definition. See stage-background-correction-report.md.

Base: `b971c7fe181315f8f8ad5a784a7b8ba14bce24fe`, branch `codex/experience-restoration`; changes remain uncommitted pending integration review. No real Spotify session or user database used by these checks.

## Reproduced causes

- `stageArtworkRect` accepted but ignored `requestedScale`; the stage size control was hidden.
- Stage image used aspect-fit but then blurred its content and placed both backdrop and foreground dark veils plus lyrics/transport over its lower edges.
- Shared foreground artwork used aspect-fill, cropping portrait/landscape covers.
- Ambient showed a second recognizable enlarged artwork at zero blur; classic compact layout required vertical scrolling to see lyrics, and classic foreground size did not consume the size setting.
- Instrumental classic imposed 4pt/1.2pt blur even at zero.

## Changes

Stage uses a shared reserved reading band (220–280pt) and a 78pt transport/metadata region. The upper stage contains one complete sharp artwork with original aspect ratio, bounded occupancy from 70% to 100% across the existing size slider, and actual left/center/right placement. The backdrop surrounds it with album-derived light without another cropped semantic image. The slider now controls the surrounding light's diffusion and is named 舞台光晕扩散. Removed both lower artwork-obscuring overlays.

Ambient retains its palette and low-frequency color field; the foreground opts into complete image fitting. Classic retains its intentionally enlarged background, complete foreground, working foreground size setting and a bounded compact split. Shared ArtworkView keeps its previous default so unrelated layouts retain compatibility. Instrumental zero blur now remains zero.

## Executed checks

- Added geometry assertions first; existing source failed with `stage size setting must change actual cover occupancy` (exit 133), proving ignored size control.
- `bash Tests/v3_responsive_geometry_contract.sh`: PASS after change. Tests 760×520, 1040×680 and 1440×900, aspects 0.2/0.65/1/1.8/5, small/large sizing, left/center/right placement, aspect preservation, canvas containment, reading-band clearance; existing responsive geometry cases also pass.
- `bash Tests/v3_ambient_backdrop_contract.sh`: PASS (legacy structural check only).
- `bash Tests/v3_responsive_ui_finish_contract.sh`: PASS (legacy structural check only).
- `bash Tests/v3_artwork_presentation_contract.sh`: PASS.
- `bash Tests/v3_cover_layout_contract.sh`: PASS.
- `bash Tests/v3_visual_tuning_reactivity_contract.sh`: PASS.
- `bash Tests/v3_artwork_resolution_contract.sh`: PASS.
- `bash Tests/v3_backdrop_contract.sh`: PASS.
- `bash Tests/v3_background_composition_contract.sh`: PASS; replaced the old string test that required the removed veil and mis-scanned classic masks as stage masks with execution of the geometry contract. This is explicitly not visual-quality proof.
- `git diff --check`: PASS at this stage.

## Visual evidence and limitations

Native integration host and Debug/Release builds are owned by root integration. No screenshot has yet been inspected by this subtask; root will supply deterministic edge-marked artwork renders, normal/compact/portrait/landscape/bright/no-artwork/instrumental fixtures and verify actual SwiftUI layout. Geometry proves containment, not the actual rendering result. No live transport, track-transition, Reduce Motion or Spotify playback claim is made here. Final visual review remains required before delivery.

## Native review iteration 2

Inspected root-provided `/tmp/lyrics-experience-visual-host/renders/stage-portrait.png` (1152×720). All edges survived, but the ~214×320 artwork occupied too little of the stage with a large unused side area. This invalidated the initial fixed lower-band composition for portrait artwork.

Added a dominance regression first: a 1152×720 portrait at standard scale must occupy at least 480pt in height. Initial code failed with `portrait stage must use available height rather than remain a small upper card` (exit 133). Revised geometry uses near-full-height artwork when portrait/square artwork leaves a readable adjacent region; landscape/center positions retain a lower reading region. Existing cover load publishes its aspect ratio to foreground via a SwiftUI preference, so no second loader or playback path is introduced. HUD remains integrated at the bottom. Standard portrait height is now about 511pt rather than 320pt; size control spans 80%–100% occupancy, with standard at 90%.

Expanded regression asserts actual artwork/reading-region nonintersection for left, center and right, across all previous dimensions/aspects; all pass. Swift parsing and `git diff --check` pass. Revised actual images remain pending root rebuild/render; the first screenshot is evidence of an issue, not acceptance.

## Native review iteration 3 — aspect propagation

Inspected `stage-portrait-1152x720-r2.png` and `stage-landscape-760x520-r2.png`. Backdrop aspect fitting was correct, but foreground reading placement remained based on the default square ratio: portrait lyrics began around x612, and compact landscape lyrics incorrectly remained at the right. Independent review reproduced the same finding and noted panoramic covers could therefore overlap lyrics. The native images exposed a real SwiftUI propagation failure that pure geometry tests cannot catch.

Replaced the preference emitted within backdrop GeometryReader with an explicit optional snapshot callback. The validated loaded artwork reports its aspect to parent state on MainActor; a new/no-artwork request resets it to 1. The single shared loader remains unchanged. Native re-render is required to verify corrected foreground placement. Pre-existing per-mode blur persistence compatibility checks were restored independently in the background-composition contract, while obsolete rendering string assertions remain replaced by geometry execution.

## Native review iteration 4 — complete current verse in the lower band

Inspected `stage-landscape-760x520-r3.png` and `stage-panorama-1152x720-r3.png`. Native foreground now follows actual aspect ratio (portrait starts around x427, landscape reading moves below the cover), confirming the snapshot callback fix. The short lower region nevertheless exposed a separate issue: full-document center anchoring and top/bottom fading cut the active original at the top in landscape and faded the translation at the bottom in panorama.

The short lower stage region now uses only the current verse from the same `state.lyrics`/`currentLineIndex`, rendered through the existing multi-layer production row. It starts at the top, has no text fade, and remains vertically scrollable for unusually long original/auxiliary blocks. Row/session identity resets the scroll for a new verse. Side-reading stage layouts keep the full document with adjacent context. No independent timeline, provider or selection was added.

Swift parsing, geometry regression and diff whitespace checks pass. Existing `v3_lyrics_scroll_stability_contract.sh` fails its stale requirement for `let lines = state.liveLyrics`; current code already used `state.lyrics` before this change to support preview sessions. The contract failure is unrelated to lower-band rendering and is reported for root integration, not bypassed. Native r4 normal/long verse acceptance remains pending.

## Root r4 native and independent review

Native r3 verified portrait aspect callback moves reading x612→427 and landscape to lower band; r4 fixes current-row clipping. Inspected `stage-landscape-760x520-r4.png`, `stage-panorama-1152x720-r4.png`, and long multilingual variant under `/tmp/lyrics-experience-visual-host/renders/`: all four artwork corners visible, no cover/lyrics overlap; current original begins fully visible with no fading. Long companion layers remain scrollable, not promised simultaneously at minimum size. Independent final code review found timed search-preview first-line-only regression; root excluded search preview from currentVerseOnly and reviewer confirmed full-document route. No remaining actionable scoped findings. Ambient bright and classic compact native r2 images were independently inspected without additional findings.

# Experience Restoration Implementation Plan

> Execute using subagent-driven-development for bounded independent work, with root integration and runtime/visual review. User has explicitly authorized autonomous multi-round iteration.

**Goal:** Fix confirmed reliability bugs and deliver restored Dynamic Island, polished desktop lyrics and three correct V3 artwork presentations.
**Architecture:** Existing shared playback/session/repository; native SwiftUI surfaces and AppKit window geometry; no second runtime.
**Tech Stack:** Swift, SwiftUI, AppKit, SQLite, shell/Swift contracts.

## Global constraints

macOS 14+, retain data and presentation IDs, no generator, no historical source overwrite. Worktree /private/tmp/spotifylyrics-experience-restoration-20260905. User primary checkout unchanged. Reference location /Users/apple/backup/sptifylyrics/.local/reference-projects. Testing databases/DerivedData under /tmp. Save/push reversible checkpoint before substantive edits. No release retagging.

## Task 1 — Reliability repair

Files: Services/PlaybackState.swift; Persistence/SQLiteLyricsRepository.swift; Windows/MenuBarLyricsController.swift; Views/MainWindow/MainLyricsWindowView.swift; Views/Settings/{ListeningHistoryView,ListeningStatisticsView}.swift (resolve actual history filename first); associated Tests.

- [x] Reuse review evidence to create failing behavior cases: preview B adoption leaves live A unchanged, exclusive DB lock throws, failed history/statistics retain last good values and retry recovers, Settings action invokes injected environment handler.
- [x] Fix source dependencies of listening_history_contract.sh and sqlite_session_contract.sh, run actual assertions.
- [x] Route candidates to preview when visible; maintain identity guard.
- [x] Add native openSettings handler; bind from SwiftUI view environment.
- [x] Check terminal SQLite read result, expose honest load errors, offer retry and retain last good values.
- [x] Run relevant contracts and Debug build; independent task review, fix findings, intentional commit.

## Task 2 — Reference recovery

- [x] Locate README/license/source paths for notch and desktop references.
- [x] Compare actual current capsule/floating implementation, record product gaps and concrete geometry/interaction guidance in docs/research/2026-09-05-presentation-reference-recovery.md.

## Task 3 — Dynamic Island

Files: Views/Capsule/*, Windows/CapsuleLyricsWindowController.swift, Capsule persistence/geometry/presentation types, PresentationCatalog and applicable settings controls/tests.

- [x] Inspect current release gating and top-attached prototype; reproduce missing/inaccessible behavior.
- [x] Add behavioral geometry tests for notched/non-notched screen, collapsed/hover/expanded transitions and click-through bounds.
- [x] Implement production availability and top-attached geometry; use notch safe area for content, maintain global menu recovery.
- [x] Render compact/expanded and verify More popover interactions; iterate on clipping, hierarchy and transition issues. Physical hover/transport/display lifecycle remains a documented manual validation limit.
- [x] Test Debug/Release, independent review, commit.

## Task 4 — Desktop lyrics

Files: Views/Floating/*, Windows/FloatingLyricsWindowController.swift, Floating presentation helpers/settings/tests.

- [x] Inspect actual desktop renderer and reference guidance; validate long lines/current-line selection and hover controls.
- [x] Implement clear typography, companion hierarchy, bounded resizing, unobtrusive discoverable controls, reliable interaction-mode recovery.
- [x] Render wide/narrow multi-language states; verify window lock/pass-through/restore flags and actual lock/style controls; independent review and commit. Cross-display dragging and long real track transitions remain manual validation limits.

## Task 5 — Three main styles

Files: Views/Components/AppleMusicImmersiveV3BackdropView.swift, Views/MainWindow/AppleMusicImmersiveV3WindowView.swift, Design/V3ResponsiveGeometry.swift and associated tests/settings.

- [x] Reproduce complete-cover stage issue with edge-marked square/portrait/landscape fixtures.
- [x] Test stage aspect-fit containment and setting size/position behavior; inspect ambient and classic composition.
- [x] Correct full-cover canvas/layout/blur semantics; polish all three styles while retaining distinct identities and controls.
- [x] Render normal/compact/bright and square/portrait/landscape/panoramic artwork matrices; cover instrumental/no-artwork paths with focused checks; iterate from native images; independent review and commit.

## Task 6 — Integration and delivery

- [x] Full branch review of every requested end-state item; resolve material findings.
- [x] Focused contracts + Debug/Release build + actual native rendered/interaction evidence.
- [x] Update STATUS honestly, verify no user data staged, commit/push each completed stage.
- [x] Materialize named preview build with source/build manifest; sync Obsidian. Do not claim completion until all user requirements verified.

## Task 4 addendum — desktop typography replacement

- Add failing pure tests for font bounds, single/double companion selection and no fabricated word timing.
- Add scoped persisted desktop typography/mode/theme fields; independently build outlined text and hover transport/style controls.
- Keep shared auxiliary visibility controls and exact timed-span validation; retain old renderer ID and stored frames.
- Root builds isolated native host; inspect large-text wide/compact, bright background, companion/readings and real timing fixtures before accepting.

## Delivered preview

Implementation commit `065564c259b3a6ba8f8209934d3bc43a00880de7` is pushed on `codex/experience-restoration`. Preview: `/Users/apple/Downloads/LyricsQ-experience-20260905-065564c/SpotifyLyrics-experience-preview.app`. BUILD_INFO.md records the exact build, executable hash, matching production source manifest and user-acceptance boundary. Detailed actual evidence and remaining device checks are in `docs/work/experience-restoration/integration-report.md`; checked implementation tasks do not imply unperformed physical hardware or long-playback tests passed.

# Experience Restoration Implementation Plan

> Execute using subagent-driven-development for bounded independent work, with root integration and runtime/visual review. User has explicitly authorized autonomous multi-round iteration.

**Goal:** Fix confirmed reliability bugs and deliver restored Dynamic Island, polished desktop lyrics and three correct V3 artwork presentations.
**Architecture:** Existing shared playback/session/repository; native SwiftUI surfaces and AppKit window geometry; no second runtime.
**Tech Stack:** Swift, SwiftUI, AppKit, SQLite, shell/Swift contracts.

## Global constraints

macOS 14+, retain data and presentation IDs, no generator, no historical source overwrite. Worktree /private/tmp/spotifylyrics-experience-restoration-20260905. User primary checkout unchanged. Reference location /Users/apple/backup/sptifylyrics/.local/reference-projects. Testing databases/DerivedData under /tmp. Save/push reversible checkpoint before substantive edits. No release retagging.

## Task 1 — Reliability repair

Files: Services/PlaybackState.swift; Persistence/SQLiteLyricsRepository.swift; Windows/MenuBarLyricsController.swift; Views/MainWindow/MainLyricsWindowView.swift; Views/Settings/{ListeningHistoryView,ListeningStatisticsView}.swift (resolve actual history filename first); associated Tests.

- [ ] Reuse review evidence to create failing behavior cases: preview B adoption leaves live A unchanged, exclusive DB lock throws, failed history/statistics retain last good values and retry recovers, Settings action invokes injected environment handler.
- [ ] Fix source dependencies of listening_history_contract.sh and sqlite_session_contract.sh, run actual assertions.
- [ ] Route candidates to preview when visible; maintain identity guard.
- [ ] Add native openSettings handler; bind from SwiftUI view environment.
- [ ] Check terminal SQLite read result, expose honest load errors, offer retry and retain last good values.
- [ ] Run relevant contracts and Debug build; independent task review, fix findings, intentional commit.

## Task 2 — Reference recovery

- [ ] Locate README/license/source paths for notch and desktop references.
- [ ] Compare actual current capsule/floating implementation, record product gaps and concrete geometry/interaction guidance in docs/research/2026-09-05-presentation-reference-recovery.md.

## Task 3 — Dynamic Island

Files: Views/Capsule/*, Windows/CapsuleLyricsWindowController.swift, Capsule persistence/geometry/presentation types, PresentationCatalog and applicable settings controls/tests.

- [ ] Inspect current release gating and top-attached prototype; reproduce missing/inaccessible behavior.
- [ ] Add behavioral geometry tests for notched/non-notched screen, collapsed/hover/expanded transitions and click-through bounds.
- [ ] Implement production availability and top-attached geometry; use notch safe area for content, maintain global menu recovery.
- [ ] Render compact/expanded, exercise hover/playback/close and reopen; iterate on clipping, hierarchy and transition issues.
- [ ] Test Debug/Release, independent review, commit.

## Task 4 — Desktop lyrics

Files: Views/Floating/*, Windows/FloatingLyricsWindowController.swift, Floating presentation helpers/settings/tests.

- [ ] Inspect actual desktop renderer and reference guidance; validate long lines/current-line selection and hover controls.
- [ ] Implement clear typography, companion hierarchy, bounded resizing, unobtrusive discoverable controls, reliable interaction-mode recovery.
- [ ] Render wide/narrow multi-language states; verify drag/lock/pass-through/restore and no stale track lyrics; independent review and commit.

## Task 5 — Three main styles

Files: Views/Components/AppleMusicImmersiveV3BackdropView.swift, Views/MainWindow/AppleMusicImmersiveV3WindowView.swift, Design/V3ResponsiveGeometry.swift and associated tests/settings.

- [ ] Reproduce complete-cover stage issue with edge-marked square/portrait/landscape fixtures.
- [ ] Test stage aspect-fit containment and setting size/position behavior; inspect ambient and classic composition.
- [ ] Correct full-cover canvas/layout/blur semantics; polish all three styles while retaining distinct identities and controls.
- [ ] Render normal/compact/instrumental/no-artwork/bright artwork matrices; iterate from images rather than string tests alone; independent review and commit.

## Task 6 — Integration and delivery

- [ ] Full branch review of every requested end-state item; resolve material findings.
- [ ] Focused contracts + Debug/Release build + actual native rendered/interaction evidence.
- [ ] Update STATUS honestly, verify no user data staged, commit/push each completed stage.
- [ ] Materialize named preview build with source/build manifest; sync Obsidian. Do not claim completion until all user requirements verified.

## Task 4 addendum — desktop typography replacement

- Add failing pure tests for font bounds, single/double companion selection and no fabricated word timing.
- Add scoped persisted desktop typography/mode/theme fields; independently build outlined text and hover transport/style controls.
- Keep shared auxiliary visibility controls and exact timed-span validation; retain old renderer ID and stored frames.
- Root builds isolated native host; inspect large-text wide/compact, bright background, companion/readings and real timing fixtures before accepting.

# Experience restoration — integration evidence

2026-09-05. Implementation worktree: `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/experience-restoration`, based on fresh main `fb95a9eaa6555d0dbccdf1fa9287bd2125c6ef16`. The protected primary checkout at `/Users/apple/backup/sptifylyrics` remains on `27435d5` with its original uncommitted paths. Exact delivered commit is recorded in the external preview package BUILD_INFO.md and Obsidian handoff after commit/push. No merge, release/tag rewrite or accepted-build archive is implied.

## Delivered behavior

- Preview candidate adoption follows the preview session, menu-bar Settings uses the retained native route, and history/statistics report SQLite read errors while retaining prior successful results and allowing retry.
- The independently implemented top-attached island is default in both configurations, reserves camera space, supports explicit expansion/collapse, hover, transport and More actions. Saved explicit v2 remains compatible. Third-party reference code/assets are not imported; temporary MIT import and notices were completely removed.
- Transparent desktop lyrics have outlined large text, independent typography/themes, single/double horizontal rows, translation/reading/next-row selection, and shared real timed-unit coloring. Locked mode has an in-window unlock.
- Stage shows complete artwork at the actual aspect ratio and allocates the reading area according to orientation; ambient and classic retain distinct compositions. Search preview still shows the full document.

## Verification

Reliability milestone `fb4b9c5`: five suites and independent review passed; see reliability-report.md for exact commands/evidence. Three-style milestone `8117313`: seven focused suites, 45 geometry combinations, native r1–r4 iteration and independent final review passed; see three-styles-report.md.

Final rerun: each of these commands passed (combined output `/tmp/lyrics-experience-final-contracts.log`):

```sh
bash Tests/capsule_lyrics_contract.sh
bash Tests/capsule_presentation_interface_contract.sh
bash Tests/capsule_v4_shape_contract.sh
bash Tests/capsule_v4_top_attached_contract.sh
bash Tests/capsule_window_behavior_contract.sh
bash Tests/capsule_v4_content_contract.sh
bash Tests/capsule_v4_reference_motion_contract.sh
bash Tests/presentation_selection_store_contract.sh
bash Tests/presentation_catalog_preview_contract.sh
bash Tests/floating_lyrics_contract.sh
bash Tests/floating_window_behavior_contract.sh
bash Tests/phase2_2_floating_presentation_contract.sh
bash Tests/phase2_2_floating_coordination_contract.sh
bash Tests/settings_contract.sh
```

Both production builds passed:

```sh
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build
```

Logs: `/tmp/lyrics-experience-delivery-debug.log`, `/tmp/lyrics-experience-delivery-release.log`. Release used a fresh directory and its app has no stale ThirdPartyNotices resource. Production source hashes exactly match the final host source manifest, despite its base HEAD predating the final commit. Formal Main.swift and the project generator were not modified.

## Native evidence and limits

`Tools/experience_visual_host` builds an isolated alternate entry point with production views/controllers, generated lyrics/cover artwork, an independent defaults suite and temporary SQLite. No real Spotify transport or user DB is exercised. All five final desktop screenshots and capsule expanded/collapsed screenshots are listed in the corresponding reports and included with the preview evidence.

Actual CUA interaction opened the final island More popover; all three actions were exposed and it remained open across a separate state read. Clicking Open Main dismissed the popover. The fixture does not install the production MainLyricsWindowView registration, so this does not claim full-app main-window reopening; source review verifies routing and prior Settings host verifies its own production route. Some separate CUA calls saw an expanded island collapse; the fixture's initial explicit expansion survives more than 3 seconds and source review found no unconditional timer collapse. A continuous coordinate-based Expand → More sequence worked. No speculative fix was introduced without mouse-event cause evidence.

Final independent desktop and capsule reviews found no remaining actionable findings. The native matrix covers bright background readability, small two-row geometry, single/theme variants and real timed-unit progression. Physical camera hardware, all display/fullscreen transitions, long real Spotify playback, full VoiceOver and system Reduce Motion remain practical user-device validation limits, not asserted passes.

Final desktop CUA interaction: opened the real style popover; selected single (second lyric AX row disappeared) and warm-gold (selected radio state updated); Escape dismissed the popover. Clicked Unlock then Lock; labels and controller log changed interactive → locked. Log: `/tmp/lyrics-experience-visual-host/desktop-controls-final.log`. The slider rejected direct AX setValue as non-settable; no UI font-drag acceptance is claimed. Typography bounds and preset renderings passed independently.

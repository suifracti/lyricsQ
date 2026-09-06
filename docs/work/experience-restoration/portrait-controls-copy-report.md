# Portrait, playback controls and lyric copy — 2026-09-06

Branch `codex/lyrics-search-ambient-fix`, isolated worktree `/private/tmp/spotifylyrics-experience-restoration-20260905`; formal root user changes preserved. Earlier data/ruby batch committed and pushed as `ee91ff5` before this work.

## Changes

- Ambient/classic tall windows use a bounded complete-cover/player header and full-width independent lyric viewport. Explicit compact lyrics-focus preference takes precedence. Stage full-cover geometry and free window resizing remain intact.
- Shared playback buttons have 44pt hit targets and local hover states. Metadata retains artist/album links. Stage combines metadata, transport and seeking in one low-contrast bottom surface.
- Native760×1000 capture exposed a real parent overflow: unbounded scaled-to-fill backdrop reported1000pt width, offsetting foreground240pt. Explicit canvas frames now constrain backdrop/root composition. Fixed native captures at760×1000 ambient and800×1200 classic show full toolbar/header/lyrics.
- Lyrics version/edit panel offers a copy view. Native text selection and one-click whole-song copy coexist with passage checkboxes/select-all/clear and optional kana/romaji/translation layers. Automatic kana uses the same scoped reading cache off-main; saved corrections win and non-Japanese text fails closed.
- Right-click a lyric for copy-line, copy-whole or choose-passages. Passage copy captures the displayed document and closes on track/version changes; original lyrics/timing stay untouched.
- Optional Stage-only “增强歌词对比度” persists in UserDefaults, defaults off; on adds a0.56 black veil for bright covers. Original0.24/accessibility0.40 behavior returns when off. No image crop or aspect constraint.

## Validation

- `bash Tests/v3_responsive_geometry_contract.sh`: PASS (portrait760×1000/800×1200/900×1400 at80/100/140%, containment and preference priority).
- `bash Tests/v3_lyric_readability_contract.sh`: PASS.
- `bash Tests/v3_lyrics_scroll_stability_contract.sh`: PASS; source marker updated for shared reading-cache access.
- `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-ruby-integrated CODE_SIGNING_ALLOWED=NO build`: PASS; latest log `/tmp/lyrics-complete-debug.log`.
- Native fixture `--copy-contract` asserts layer formatting, empty content, passage ordering, automatic kana, corrected stored readings and Chinese isolation; final native extended run PASS (`/tmp/lyrics-white-stage-off.log`, `LYRICS_COPY_CONTRACT_PASS`).
- Independent bounded review of copy/context menu/stage toggle: no blockers.

- Release build PASS: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-final-experience-release CODE_SIGNING_ALLOWED=NO build`, log `/tmp/lyrics-final-release.log`.
- Final host build PASS: `python3 Tools/experience_visual_host/build.py` (temporary full-source fixture); white Stage off/on renders at1152×720 show increased lyric contrast. Settings default-off and persistence asserted against isolated defaults in fixture startup.
- Native CUA: right-click active lyric → all three menu items → choose passages opens with that line checked; additional line and kana toggle update preview, clear disables copy; after close playback slider remains18seconds. User clipboard was not overwritten for tests.
- Native normal portrait900×1400 request was constrained by macOS to900×1325 and rendered correctly. Ambient1152×720 and stage1152×720 also reviewed. Separate140%/long-line fixture launches stalled before opening a window; geometry covers these bounds, but native combined140%+long-line remains unverified. No claim of full1400px native validation.
 No production database changes or user playback seeks performed for tests. Preview remains a feature branch, not merged into main.

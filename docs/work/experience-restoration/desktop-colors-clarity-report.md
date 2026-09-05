# Desktop lyric clarity and colors

Implementation base: clean `85e99ec48fcb2977586ac90f74c53cfba0cb7511` checkpoint on `codex/lyrics-search-ambient-fix`. Current changes are uncommitted. No real playback controls, user database, application UI, or full product build operated by this subtask.

## Source evidence and corrections

The transparent renderer previously used white unplayed/companion text, preset-only highlights and a blurred drop shadow rather than glyph outline. Whole-window alpha dimmed text and shadows together. Fixed-height primary/companion ribbons omitted explicit stroke/ruby height budgets.

- Added five persistent RGB color overrides: original, sung/highlight, ruby/reading, translation and outline. Empty overrides inherit existing mint/amber/ice presets. Malformed hex (including embedded # and alpha-bearing forms) safely falls back. Pickers and a reset action are shared by the desktop popover and Settings.
- Added configurable outline width, default 1.25pt. `OutlinedLyricText` is a shared drawing primitive backed by AppKit attributed glyph stroke/fill, with no blur or timing. Intrinsic size includes clear stroke insets. Repeated unchanged updates avoid invalidating intrinsic size.
- Transparent desktop primary, top ruby and auxiliary text consume the palette and the real outline primitive. The shared `RubyLineView`, reading projection and presentation clock implement word progress; no separate progress engine or synthetic spans were introduced. Plain transparent rows reuse the desktop renderer with synchronization explicitly disabled.
- The ribbon font fitting budget now includes top annotation height, original/companion lines, stroke insets and spacing. At the 120pt panel minimum it can reduce the requested font below the normal slider minimum rather than clip glyphs. Long text still has horizontal reveal/manual drag.
- `floatingDesktopKeepsTextOpaque` defaults true for the transparent renderer. This makes panel alpha 1 and applies the existing opacity value to the background only. An explicit “文字保持不透明” toggle and dynamic background/whole-window label explain the target; disabling it restores whole-window alpha. Legacy panel alpha and presentation behavior remain unchanged.

## Checks

- Added pure contracts for color parsing, fallback, rejection of alpha-bearing values, outline width bounds, legacy/transparent opacity behavior, and minimum-height top-ruby containment. Missing new APIs failed before implementation; malformed embedded-# regression failed against the initial parser and passed after correction.
- `Tests/floating_lyrics_contract.sh`: PASS.
- `Tests/floating_outline_render_contract.sh`: PASS. Compiles the actual drawing primitive extracted from its source, draws Latin/CJK glyphs into an isolated NSBitmapImageRep, verifies opaque outline and fill pixels and a transparent corner. No source-string assertion substitutes for its pixel checks.
- `Tests/floating_window_behavior_contract.sh`: PASS.
- `Tests/phase2_2_floating_presentation_contract.sh`: PASS.
- Swift parsing of affected views/controller/settings and `git diff --check`: PASS.

Root owns full compilation and native host visual acceptance. Required final inspection: 360×120 and normal-size panels, top kana with translation, long lines, real timed fill at multiple positions, custom colors on bright/dark/patterned backgrounds, no-art/loading/plain states, text-opaque/background opacity mode and explicit whole-window opacity mode. The raster primitive test proves actual glyph stroke, not complete product layout or visual acceptance.

# Hover playback, desktop clarity and shared timed readings

Base e08c54732082ce7ea21e0e378110f0a69e40d8ec, branch codex/lyrics-search-ambient-fix in isolated worktree. Formal root dirty user work remains protected. This is continued user-authorized preview iteration, not a new main merge. Current Obsidian handoff read; historical Craft connector read attempted but transport unavailable, so user request controls scope.

## Scope and design

1. Diagnose current stb アーカイブ - Piano Ver.22sec missing ruby using read-only saved lines/provider readings; fix proven alignment/display cause with fail-closed regression (no guessed alignment).
2. Reproduce click-to-seek failure in isolated provider/slider fixture. Preserve clicked target through callback ordering; reject stale playback snapshots during bounded seek acknowledgment if evidence supports it. Use existing local Spotify provider, no new network dependency.
3. Optional persisted hover-only playback information for allthree V3 presentations, default off. Entering window reveals metadata/transport/progress; exit fades controls and disables hidden hit targets. Keep reveal during interactions/popovers. Ambient/classic complete artwork may subtly scale/shift in its reserved region; lyrics and window dimensions remain stable, reduce-motion avoids transforms. Stage complete cover remains unchanged.
4. Desktop readability: inspect outline, line bounds/companions and clipping; support persisted custom base/highlight/auxiliary/outline colors while retaining presets and transparent surface. Use bounded no-blur text rendering.
5. Share existing word timing/progress and ruby projection between desktop and player. Real timed spans drive precise highlighting; missing spans must remain explicitly line-level or clearly labeled estimated fallback, never stored as real timing. Preserve click-ruby editing and existing source/version selection.

## Ownership and execution

- Parent: hover setting/rendering and integration, full builds/native captures/docs/delivery.
- Seek agent: local command/projection/slider diagnosis and focused regression; coordinate V3 progress subsection changes with parent.
- Ruby/timing agent: missing-ruby diagnosis plus common projection/progress restoration; coordinate main renderer and desktop owner.
- Desktop agent: typography/contrast/custom colors; coordinate AppSettingsStore property additions, no conflicting timed renderer edits.
- Every functional patch follows reproduced failing case → minimal fix → focused validation. No user DB mutations or Spotify seeks for tests.

## Completion gate

Focused ruby/seek/desktop/geometry/timing tests, source review and diff-check; standard Debug/Release (task-specific /tmp DerivedData). Isolated native tests of seek click, missing22sec ruby, hover enter/exit with three layouts, desktop light/dark backdrops/custom colors and timed/no-timing cases. Report any native limitation honestly. Commit/push explicit paths, verify upstream equality, create unique Downloads preview with SHA/BUILD_INFO, keep old app, update Obsidian Current. No generator, destructive git commands or automatic main merge.

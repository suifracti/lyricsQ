# Desktop lyrics restoration — implementation evidence

Source: shared worktree `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/experience-restoration`, base HEAD `b971c7fe181315f8f8ad5a784a7b8ba14bce24fe` plus uncommitted changes. No commit/push performed by this subtask.

## Changes

- Reserve a 36 pt toolbar strip in layout. Hover changes opacity without moving text or covering it. Locked mode exposes the same in-window unlock action; pass-through recovery remains the existing application menu.
- Desktop synchronized projection starts at the current verse. Panels shorter than 280 pt devote scrolling space to that verse; taller panels include the next verse. Intro projection remains bounded and paused current lines remain selected.
- Scroll to the top of the current verse rather than its center, so long verses begin with their first words. Companion layers remain available through scrolling and retain shared kana/romaji/pinyin/translation preferences and language gating.
- Bound desktop typography separately from the main-stage size preference; add close and diffuse dark text shadows on transparent lyrics. The transparent idle panel has no visible border; hover reveals a faint frame. Both existing presentation stable IDs are retained.
- Hover respects Reduce Motion. The renderer continues to consume only the shared live projection; no provider, timer, storage or settings owner is added.

## Red / green

1. Changed real selection assertions to require current plus next (indices 3...4) and a bounded two-line intro (0...1). `bash Tests/floating_lyrics_contract.sh` failed with a precondition at line 17 against the original helper (exit 133). This catches surrounding verses displacing the reading target.
2. Added geometry assertions for minimum width and compact/tall row budgets. Before implementation, the same command failed to compile because `FloatingLyricsLayout` was absent (exit 1; API red, not a runtime behavioral failure).
3. After implementation, `bash Tests/floating_lyrics_contract.sh` passed. It executes production timeline/selection/layout helpers.
4. `bash Tests/phase2_2_floating_presentation_contract.sh` passed. The old interactive-only controls string assertion was intentionally revised because locked in-window recovery is now required. This remains wiring coverage, not visual proof.
5. `bash Tests/phase2_2_floating_coordination_contract.sh` passed.
6. `git diff --check` for owned changes passed.
7. `bash Tests/floating_window_behavior_contract.sh` initially failed its global timer source count: baseline acceptanceControlTimer plus the production polling timer. Root verified both already exist in HEAD. Narrowed this wiring check to production `startTimer()` while retaining no-floating-timer checks; now passes.

## Native evidence

The isolated host was updated with directly injected settings/controllers for floating and capsule, correct NSPanel capture/size, retained translation plus optional kana/romaji in the long fixture, and runtime flag/frame-clamp assertions. Root built the host from this shared worktree.

- `run.py --surface floating --width 360 --height 120 --long-line --aux-layers --floating-behavior-checks --output /tmp/floating-360x120.png` exited 0 and printed `FLOATING_BEHAVIOR_CHECKS_PASSED`. Actual panel assertions: locked disables both drag flags and resize while accepting mouse events; pass-through ignores events; restoreInteractiveMode reenables drag/resize and event handling. Production persistence clamps a huge frame inside a negative-origin 1280×800 display to 960×640. Fixture database: `/tmp/lyrics-experience-visual-host/fixtures/run-583EDABD-65B3-4D99-BA06-A58585969008/fixture.sqlite3`; log explicitly reports formal_database_opened=NO.
- `/tmp/floating-620x220.png`: actual production floating renderer, long Japanese original + kana + romaji + Chinese translation. Inspected image: original wraps inside horizontal margins; all companions fit, original has clear priority. No always-visible toolbar/card covers the text.
- `/tmp/floating-620x320-locked.png`: same long fixture in locked mode. Current verse plus next verse fit. No text overflow beyond horizontal bounds.
- `/tmp/floating-360x120.png`: current verse begins at its first words; longer content exceeds the short viewport vertically and is scrollable. This intentionally does not promise all companion layers simultaneously at the minimum size. Automatic scroll indicators improve discoverability.

The image captures have transparent pixels; their black viewer backdrop alone does not verify contrast on bright desktops. Full shared build manifest lives under `/tmp/lyrics-experience-visual-host`; root owns immutable source/build evidence. A final build must include the last `.scrollIndicators(.automatic)` change if the first host snapshot preceded it.

## Remaining manual limits

Actual NSPanel interaction flags pass, but clicking the in-window unlock with CUA was not completed: selecting the fixture app focused its main window and covered the normal-level floating panel. The fixture process was stopped; no real product process was closed. Root is advised to enable always-on-top in the isolated fixture for a subsequent visible interaction check. No CGEvent/warp/AppleScript UI automation was used.

The optional capsule synthetic hover check in the host must not be used as acceptance: the controller rechecks the real cursor during state transitions. Root and capsule agent were notified to use actual CUA interaction instead.

Real Spotify playback, cross-display drag/restart, bright desktop contrast, full VoiceOver navigation and system Reduce Motion toggling have not been performed by this subtask. Source-only contracts and programmatic window properties do not prove those behaviors.

## Root native interaction follow-up

2026-09-05: With a WindowGroup fixture (so hiding main does not terminate the app), CUA selected the real floating NSPanel. Actual click `解锁悬浮歌词` changed accessible label to `锁定悬浮歌词` and controller readback to `FLOATING_MODE interactive`; clicking again restored `已锁定` and `FLOATING_MODE locked`. Log: `/tmp/lyrics-experience-visual-host/floating-ui-final.log`. Quit only the isolated fixture afterward. This closes the earlier in-window unlock verification gap.


## Second iteration — user-requested desktop product treatment

The user explicitly rejected the first generic small-font desktop treatment and requested QQ/NetEase-like desktop lyrics. Root inspected public reference screenshots; this implementation independently recreates familiar behavior, with no copied code or assets.

- Transparent V2 now has its own centered outlined 34 pt text renderer, mint/amber/ice themes and desktop-scoped 22–64 pt adjustment. The retained legacy renderer remains selectable by the existing ID.
- Single/double choice; second line defaults to enabled translation and falls back to the next verse, with explicit kana/romanized-reading/next-line choices. Shared original, translation, kana mode, romaji and pinyin preferences remain editable in the hover popover. Desktop typography does not mutate main-window font preferences.
- Hover strip includes previous/play-pause/next, typography popover, lock/unlock, pass-through and hide. The control strip remains reserved and popover presentation keeps controls visible.
- Real timed spans feed the existing validated TimedTextComposer using shared currentTime. Sung/active units receive the accent, future units remain white. Untimed lines receive a uniform accent; no line-level timestamp is converted into fabricated word progress. Current implementation colors timed units and does not claim a continuously clipped glyph sweep.
- Unsaved default frame is 820×180, centered horizontally 64 pt above the visible screen bottom. Existing saved frames continue through unchanged restoration/clamping.

Second-iteration test evidence: new helper API tests failed before implementation with missing FloatingDesktopTypography (compile/API red). Font bounds, single/double translation-next selection, no untimed synthetic progress, real two-character half-span progress [0.5,0], and nonfinite time fail-closed behavior pass after implementation. Floating behavior/presentation/coordination and settings wiring contracts pass. Existing implicit transport source ban was intentionally narrowed to implicit seek/clock mutation because explicit desktop transport is now requested.

The earlier native screenshots document iteration one only. Root owns iteration-two native builds, screenshots and real interaction acceptance; do not treat first-iteration images as proof of the new renderer.


## Reviewer follow-up — true desktop ribbons

Independent review caught that the first large-font implementation still allowed unlimited wrapping, misrepresented single/double rows, exposed unsupported global ruby-mode effects, and let an empty translation block valid reading fallback. Fixed before accepting the second iteration:

- V2 primary and companion are each one measured, clipped horizontal ribbon. Font fitting accounts for available height and double-row spacing; 360×120 double-row layout is bounded rather than vertically scrolling off-screen. Shared currentTime and the existing verse interval reveal long text spatially from start to end; this reveal is independent from real timed-span highlighting. No added timer. Manual horizontal dragging permits paused reading; Reduce Motion disables automatic reveal.
- Desktop popover offers kana visibility/second-row selection and explicitly says desktop readings use the second row. It no longer offers inline-ruby/kana-replacement formatting as desktop effects or mutates the existing main-window kana format through a mode picker.
- Primary fallback ignores empty/whitespace-only enabled layers before using available kana/romanization.

Pure test additions were API-red before implementation, then green: empty translation fallback; 800-point text in 300-point viewport starts at offset0 and reaches500 at interval end; short content never pans; 84-point available reading height fits both rows at no smaller than22pt. All four floating contracts and settings contract pass. Native evidence must use a build containing this follow-up, not earlier wrapping renderer captures.

## Final native matrix and review

The final host build includes bounded horizontal ribbons and blank-layer fallback. Native captures under `/tmp/lyrics-experience-visual-host/renders` were inspected:

- `desktop-mint-early.png` and `desktop-mint-late.png`: same generated line at 18/21 seconds; true timed-unit color advances and unsung text remains white.
- `desktop-bright.png`: native white backing; original and translated text remain legible with dark outlines.
- `desktop-small.png`: 360×120 long Japanese verse; original and translation each occupy one bounded row. The original is horizontally revealed at the shared playback position.
- `desktop-single-amber.png`: 620×160 single centered original, warm-gold theme, no second row.

All five fixture processes exited 0. Final independent read-only review found the three earlier findings resolved and no new actionable regression. The final 14-suite capsule/desktop/settings rerun passed; production Debug and fresh Release builds passed. These fixture images are not real Spotify playback evidence.

Final desktop CUA interaction: opened the real style popover; selected single (second lyric AX row disappeared) and warm-gold (selected radio state updated); Escape dismissed the popover. Clicked Unlock then Lock; labels and controller log changed interactive → locked. Log: `/tmp/lyrics-experience-visual-host/desktop-controls-final.log`. The slider rejected direct AX setValue as non-settable; no UI font-drag acceptance is claimed. Typography bounds and preset renderings passed independently.

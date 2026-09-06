# Native fullscreen, lyric placement and status-bar text — 2026-09-06

Second user-queued batch after published checkpoint 2d7a104. Feature branch codex/lyrics-search-ambient-fix; formal root remains protected.

## Behavior

- One retained normal NSWindow enters a native fullscreen Space with window-scoped automatic Dock/menu hiding. Entering, visible, exiting and hidden states handle queued exit, failed transitions and auxiliary-window restoration. Escape dismisses an active popover/sheet first; ordinary Escape exits fullscreen. Intentional screen-edge Dock reveal follows macOS behavior.
- Fullscreen uses maintained V3 Ambient/Classic/Stage with live-only document/track/revision/copy/readings, preserving any independent main-window search preview. Scene bridges keep Library, Settings and lyric editor functional. Unavailable desktop/capsule toggles are omitted in fullscreen; Return to Main remains.
- Lyric placement and alignment is stored per artwork presentation: Automatic, Left, Center, Right. Stage moves the reading region without changing cover geometry; all styles align original/ruby/translation and each wrapped ruby row. Center/trailing margins mirror correctly. Fullscreen increases the reading measure and font scale by a bounded factor up to1.5 on large screens; normal windows retain their existing scale.
- Menu-bar lyric text has a default-on, persisted switch in the status-bar popover and General Settings. Off keeps the music/pause icon and popover access; changing the switch repaints immediately without waiting for playback state to change.

## Native evidence

- Fullscreen fixture confirms native styleMask/fullScreenPrimary, exit and retained-window reentry. Ambient log prints FULLSCREEN_NATIVE_ENTERED and FULLSCREEN_BEHAVIOR_CHECKS_PASSED.
- Stage fullscreen showed only live lyrics while main retained deliberately different UNPLAYED PREVIEW lyrics. CUA Escape exited the window. No permanent Dock was visible in native fullscreen captures.
- CUA changed Ambient Right → Classic Center → Ambient and confirmed Right was restored. Ruby and translation followed alignment. A final inspection corrected the outer row wrapper to apply the same alignment rather than pinning it left.
- CUA opened the fullscreen version sheet, then the actual lyric editor window with the correct live track and six fixture rows; closed without editing. Transport accessibility labels remain native; removed both root label and identifier propagation.
- Fake playback fixture only; no real Spotify seek or production lyric/database mutations.

## Verification

Focused fullscreen lifecycle/static, V3 readability, ruby wrap/geometry, seek draft/shared-fullscreen, and menu-bar toggle contracts pass. Final incremental Debug and full-source fixture builds PASS after alignment/AX corrections; manifest matches current application/project source. Final stage-right native AX exposes distinct control labels/IDs, screenshot shows correctly anchored ruby/translation and complete cover; native lifecycle checks PASS again. Existing broad phase2_1 static suite contains an old exact V3 language-expression assertion; focused maintained fullscreen contracts replace that historical architecture check. Fullscreen multi-monitor reconnection and deliberate Dock-edge reveal are not exhaustively tested.

# V3 seek input verification — 2026-09-06

The latest user clarification is that the progress bar cannot drag and Spotify receives no seek. This investigation did not control the user's Spotify or application, change playback data, or change provider/PlaybackState behavior.

## Confirmed findings

- In a standalone fake-state window matching the V3 custom rail, the original almost-transparent SwiftUI Slider and background-draggable window allowed a physical CUA drag to move the window without entering slider callbacks. Increasing opacity from 0.01 to 0.02 did not establish working drag ownership.
- A native NSSlider overlay at normal alpha, with drawing suppressed only in its cell, `mouseDownCanMoveWindow = false`, and `acceptsFirstMouse = true`, delivered clicks. The parent also confirmed an integrated host click produced a seek.
- Default NSSliderCell tracking still failed a deterministic sparse CUA drag in the integrated fixture: moving from the current knob to another endpoint committed the original position. The final implementation owns the pointer tracking loop and maps mouseDown, mouseDragged, and mouseUp coordinates across the same full-width custom rail. The mouseUp coordinate is applied before the single completion callback.
- Actual CUA verification of the final source, in an isolated 400-pixel window with a 300-pixel rail at x=50…350 and duration 240 seconds: drag `[73,112] → [280,112]` changed accessibility position 18 → **184**; reverse drag `[280,112] → [110,112]` changed 184 → **48**. The log contains exactly one `seek:184.0` and one `seek:48.0`, with no window-move notification during either gesture. Log: `/tmp/lyrics-v3-pointer-mouseup.log` (temporary evidence, not a repository artifact).

An earlier report of 176 tracking samples was not deterministic CUA endpoint evidence: user movement interrupted that run. It is superseded by the two exact endpoint checks above.

## Changes and focused checks

- V3 native input adapter preserves the custom visuals and native slider accessibility/keyboard action path. Pointer tracking owns the input, with one seek on completion; inactive-window first clicks are explicitly accepted. Window background-drag settings remain unchanged.
- V3 and legacy fullscreen draft completion retain the actual value emitted by the control instead of replacing it with live playback time when editing begins. Completion without a draft and repeated completion do not seek. The V3 callback also preserves the parent's hover controls while dragging.
- `python3 Tests/v3_seek_draft_contract.py`: PASS for both callback orders, no-value tracking, duplicate completion, refresh during tracking, and clamping; fullscreen draft contract PASS.
- `python3 Tests/v3_seek_pointer_contract.py`: PASS for full-rail mapping, endpoints, clamps, invalid geometry, and sparse endpoint value calculations. This pure contract does not claim to test AppKit event delivery; the native CUA checks above cover that separately.
- The extracted production V3 progress and native adapter compile in the isolated AppKit/SwiftUI fixture.

## Limits

The native fixture uses fake playback state. Provider delivery remains for parent integration verification. Background/title drag attempts in the isolated fixture did not produce movement notifications, so runtime preservation of those gestures is not claimed. Keyboard/accessibility action routing and inactive first-click support are implemented but were not independently exercised in the final CUA run. No network failure or provider queue defect was established.

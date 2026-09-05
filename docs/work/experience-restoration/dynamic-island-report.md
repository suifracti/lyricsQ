# Dynamic Island restoration — implementation and verification

Source: shared branch `codex/experience-restoration`, base checkpoint `b971c7fe181315f8f8ad5a784a7b8ba14bce24fe` plus this task's uncommitted changes. Formal source remains the Git checkout; no historical source restoration, project generator, real user DB, or Spotify operation occurred in this task.

## Product changes

- The existing v4 presentation is the product default in Debug and Release. The presentation catalog exposes it as current, with the existing normal application routes retained. Explicit v2 choices remain compatible and Restore Recommended returns v4. Stable IDs are unchanged.
- The existing single panel/controller now uses the physical screen top and `.statusBar` level for v4. It keeps a fixed transparent envelope across collapsed/hover/expanded states. Legacy renderers retain their prior floating window path.
- `CapsuleNotchGeometry` derives safe depth and central reserved width from `NSScreen.safeAreaInsets` and auxiliary top regions. Compact artwork and expand/status controls flank the hardware reserve. Expanded contents begin below the hardware region. No-notch displays use a compact title/artwork/control layout; negative-origin displays keep the same physical-top calculation. Missing auxiliary data with a positive safe inset reserves a conservative central width.
- Global/local pointer monitoring enables hover even while the transparent host passes mouse events through. The hit region excludes rounded transparent corners and the unused envelope. During growth it intersects the previous settled shape until the geometry animation finishes, so newly transparent space does not intercept clicks; hover detection still follows the target island. Entering dwells 450 ms before expansion; leaving collapses after 350 ms; reentry cancels pending work. Slider editing prevents collapse during an active seek. Explicit expand and collapse buttons remain available.
- Runtime catalog changes are observed by the same controller, updating frame, level, motion state and pointer handling immediately. The controller reads its injected settings selection, allowing isolated fixture suites.

## Executed checks

- Red: default test failed against v2 with `Product default must restore the island`.
- New geometry assertions initially failed to compile because `CapsuleNotchGeometry` did not exist, then passed after implementation.
- Passed: `capsule_lyrics_contract`, `capsule_presentation_interface_contract`, `capsule_v4_shape_contract`, `capsule_v4_top_attached_contract`, `capsule_window_behavior_contract`, `capsule_v4_content_contract`, `capsule_v4_reference_motion_contract`, `presentation_selection_store_contract`, `presentation_catalog_preview_contract`.
- Geometry assertions cover physical-top frame, fixed-envelope containment, central reserve, expanded safe depth, notched and non-notched screens, negative coordinates, missing auxiliary data, transparent bottom corner/outside-envelope misses, and conservative click bounds during expansion.
- Native isolated visual-host Debug compilation passed twice after controller/view integration. Build log: `/tmp/lyrics-experience-visual-host/build.log`. The host uses generated fixtures and temporary storage; this is not real Spotify evidence.
- Updated obsolete v2-current assertions to match this user's explicit restoration instruction. The old timer-count check already failed at base HEAD because it counted the DEBUG acceptance control-file timer; it now checks the single production playback timer and retains the prohibition on capsule clocks/providers/network/session ownership.

## Integration verification still required

Root integration owns the refreshed native host screenshots and real pointer behavior checks, plus full Debug/Release builds. Inspect actual compact and expanded panels, camera-area clearance on the attached physical display, rapid hover reversals, explicit collapse/reopen, menu controls, click-through next to the island, screen/fullscreen lifecycle and Reduce Motion. Synthetic geometry assertions do not constitute physical notch hardware verification. No real Spotify transport, real track transition, or user database verification is claimed here.

## Follow-up More actions review

The first native expanded screenshot exposed a dark native More icon. The final implementation uses an explicit white plain button opening a dark SwiftUI popover, with the same Open Main, Toggle Desktop Lyrics and conditional Edit Lyrics actions. Open Main uses the existing recovery route, which can invoke the retained SwiftUI openWindow handler after main-window closure.

The popover binds directly to `CapsuleLyricsWindowController.menuIsPresented`. Its presentation cancels pending hover collapse and guards outside-click collapse; dismissal resumes the ordinary pointer/AX policy. Explicit collapse/hide clears the popover. The intermediate NSMenu begin/end notification workaround was removed after native CUA exposed unstable menu dismissal; no anonymous native-menu tracking heuristic remains.

Compiled interaction tests cover popover protection and release, and syntax/window/content checks pass. Root owns actual popover AX/keyboard action verification on the refreshed native host.

## User decision: references only, independent implementation

The user clarified that if third-party reuse requires attribution, they prefer studying the reference and implementing independently. An attempted narrow MIT source import was therefore completely removed before delivery, including its source file, notices, Xcode entries and import-only tests. No copied DynamicNotchKit, boring.notch or Atoll source remains in the delivered capsule implementation. Project-wide LICENSE is unchanged.

The capsule shell and hit geometry were returned to the independently implemented pre-import version while preserving all product restoration, hardware-notch reserve, hover/input, settings selection, and native menu fixes. The upstream checkout in `/tmp` was research material only. Any host snapshot built during the short-lived import is obsolete; root rebuilds from the independent current source for delivery.

## Native AX expansion follow-up

Root's actual accessibility click log (`/tmp/lyrics-experience-visual-host/capsule-ui-final.log`) reproduced explicit expansion immediately collapsing because an AX action does not move the physical pointer. The controller now distinguishes dwell expansion from explicit expansion. A keyboard/AX expansion opened with the pointer outside waits for a real pointer entry before enabling hover exit; explicit collapse and genuine outside clicks still work. Geometry refreshes do not release this wait. Mouse-click and dwell paths retain their normal entry/exit behavior without a persistent pin.

`CapsuleExpansionInteraction` tests cover AX pointer-out persistence, real entry re-enabling exit, unpinned dwell/mouse expansion, and reset. The new test failed for the missing helper before implementation and passes afterward. The explicit More popover state also protects keyboard-open actions with the pointer outside. Syntax parse, geometry/interaction contract and capsule window contract pass; root owns the repeated actual AX/More interaction verification on the refreshed host.

## Final integration review/build

Final independent review of explicit More popover and keyboard/AX expansion state found no actionable findings. Nine capsule/catalog contracts and five desktop/settings contracts passed together. Production Debug and a fresh Release build passed; the fresh Release app has no obsolete ThirdPartyNotices resource from the removed import. Final native controls are recorded separately in the integration report.

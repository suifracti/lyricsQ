# Findings

Base fb95a9e. Four review findings located in previous report /private/tmp/spotifylyrics-review-20260905/docs/audits/2026-09-05-reliability-review/REPORT.md.
References found under primary .local/reference-projects: DynamicNotch-main, boring.notch-main, Atoll-dev, LyricsX-master, TaskbarLyrics-main, Mineradio-main.
Current three styles are V3ArtworkPresentation ambient/stage/classic. Stage already has an aspect-fit plane but also high blur/layout dependencies; must render to determine actual complaint rather than assume scaledToFit alone satisfies it.

## 2026-09-06 UI follow-up

- The activity worktree is at `492f86f6df1618ec31553791e0778b6f05579990` with one pre-existing user/agent modification in `Tests/v3_responsive_geometry_contract.swift`; preserve it.
- `AppleMusicImmersiveV3WindowView` currently derives playback visibility from `isPointerInsideCanvas`, so lyric-side hover reveals the playback details. The actual cover/player region is already laid out separately in adaptive/classic/portrait compositions; the hit region must be reported from that layout rather than inferred from a left/right half.
- Portrait uses a distinct top header with `portraitMetrics.headerHeight`; the same reported region must cover its cover, playback card and interstitial gap. Toolbar hover remains a separate state.
- Stage lyric scrolling currently uses `UnitPoint(x: 0.5, y: 0.47)`. The requested adjustment is a bounded anchor helper: add about 5% of the viewport, capped at 48pt, while retaining `0.47` outside stage.
- The existing uncommitted geometry contract is the red test for these helpers and will be kept as part of the continuation.

## Validation outcome

- The measured region is now reported with SwiftUI anchors: adaptive/classic covers the laid-out cover/player composition and portrait reports only the top header. Direct lyric-side events resolve outside the expanded reveal rect, including lyric text and the blank reading area.
- `v3_lyrics_scroll_stability_contract.sh` initially failed because it encoded the old `.leading` and `state.liveLyrics` implementation spelling. It now checks the preserved behavior semantically: eager `VStack` with shared row spacing, one selected-document snapshot, one shared current-index boundary, stable row identity, and no playback-tick scroll trigger.
- Native isolated checks passed for lyric-side hide, cover/player-side reveal, landscape ambient/classic, portrait lyric-side hide, hover-off persistence, and stage short/fullscreen composition. The CUA/AppKit progress-drag hold was not stable enough to claim actual mid-drag acceptance.

## 2026-09-06 v2 preview boundary

- `ambientHiddenCoverScale` scales only the foreground artwork while playback details are hidden; the cover remains aspect-fit and its pre-scale layout frame continues to define the hit region. Compact and portrait budgets are capped independently.
- Stage playback visibility is calculated from the entire canvas Y split, with an 8–24pt bounded hysteresis band. The existing stage lyric anchor remains bounded to at most 48pt below 0.47.
- Static evidence was regenerated for ambient/classic landscape, ambient portrait, stage landscape hidden/visible, and native-fullscreen visible. The native fullscreen hidden screenshot did not complete in the isolated renderer and is not claimed.
- The CUA fixture can send a real drag but not a move-only pointer path; drag release enters hover-ended in this host. Therefore lyric-side hide is observed, while move-only return/reveal and progress-drag hold are pending user preview, not accepted by waiting for events.

## 2026-09-06 A–H continuation and preview boundary

- Translation import is preview-first and fail-closed: timestamped input may resolve a unique fixed offset within tolerance; untimed input maps only when nonblank counts match exactly. Applying the preview changes text only; source timestamps and stable line IDs remain authoritative.
- Manual translation examples are recorded only after a saved manual edit and are kept as a bounded local style profile. Codex requests carry song context, stable line IDs, timestamps as read-only context, and confirmed style examples. The app talks to the installed Codex app-server and does not read or persist raw OAuth token files. The live contract initially exposed a real protocol mismatch: this server requires an object-root output schema, so the implementation now requests and strictly unwraps `{\"lines\": [...]}` before stable-ID validation.
- The presentation clock offset is deliberately separate from the authoritative playback position. It is clamped, persisted as a presentation preference, and used by the shared line-index/desktop paths; source LRC/provider time is not rewritten.
- Final Debug build: `/tmp/spotifylyrics-experience-restoration-a-h-debug-20260906-r2/Build/Products/Debug/SpotifyLyrics.app`; executable SHA-256 `9a8b73fdd6ba52aa906fa9fda819f7e73e135064f2bcf95f0e55c2ea6257b22f`. Build warnings are pre-existing/deprecation-style warnings; no build errors.
- Independent preview: `/Users/apple/Downloads/SpotifyLyrics-AH-Preview-20260906-Debug.app`; old `/Users/apple/Downloads/SpotifyLyrics-UI-Adjustments-Preview-20260906-v2.app` is retained. The preview is not an acceptance sign-off. Because the native fixture did not produce reliable move-only AppKit events, the following remain unverified: animated reverse travel, portrait vertical return, stage lower-half reveal, and active-drag hold after leaving the cover/player zone.

## 2026-09-06 final preview naming refresh

- The user-visible `appleMusicImmersiveV3` presentation is now named “专辑沉浸 V3”; its Catalog version is `3`. The stable catalog ID remains `mainWindow.appleMusicImmersiveV3.v3`, and the old `immersiveSplit` implementation remains available.
- The final Debug preview is `/Users/apple/Downloads/SpotifyLyrics-AH-Preview-20260906-V3-Debug.app` with executable SHA-256 `4b4322ff4b5fd89ff8ff23da6812d8d417db1c0fd1817f6c4d069fd2ef22c6ed`; build record is `/Users/apple/Downloads/SpotifyLyrics-AH-Preview-20260906-V3-Debug.build-info.txt`.
- Only the naming contract, whitespace check, and one final Debug build were run for this refresh. The preview remains a user-check candidate, not a full acceptance sign-off; move-only pointer paths, active-drag hold, and subjective stage placement remain the recorded risks.

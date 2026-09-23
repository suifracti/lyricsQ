# O1 — Scoped Lyrics Offset

- `batch_id`: `O1`
- `result`: `IN_PROGRESS`
- `base_head`: S1 final `6211bed5c2e31fa0325be00e5a2415d8563f0f25`
- `branch`: `codex/o1-scoped-lyrics-offset`
- `source_worktree`: `/private/tmp/spotifylyrics-o1-scoped-lyrics-offset`
- `upstream`: pending checkpoint push
- `human verification`: `USER_VERIFICATION_REQUIRED / NOT_RUN`

## Pre-change source identity

- Formal project root: `/Users/apple/backup/sptifylyrics`.
- S1 source checkout: `/private/tmp/spotifylyrics-s1-durable-manual-adoption`, clean at `6211bed5c2e31fa0325be00e5a2415d8563f0f25`; its upstream resolved to the same SHA.
- The H1 (`449df0a...`), T1 (`2963f71...`), T2 (`40cc1b5...`) and S1 (`e566bbf...`) production commits are ancestors of the selected O1 base.
- The root H1 checkout and three pre-existing untracked `PROJECT_FULL_AUDIT_*.md` reports remain untouched.
- A fresh fetch confirmed the S1 remote branch still points to the supplied S1 final HEAD.

## Pre-change identity and offset flow

1. Playback constructs `TrackIdentity` from the provider `Track`; its `stableKey` is the current raw identity. `SQLiteLyricsRepository` resolves redirect chains internally before persisted reads. The public `resolveStableKey` helper is concrete-repository-only and is not currently exposed by `LyricsRepository` to playback.
2. The live persisted lyrics version is `LyricsSessionController.activeLyricsVersionID`; `PlaybackState.liveLyricsVersionID` only exposes it while session identity matches the live track. The search preview uses a separate session. The editor uses its own `sourceVersionID` and loaded saved-version records; a fresh editor source uses a temporary UUID and must not be treated as persisted identity.
3. Offset is currently one `AppSettingsStore.lyricsPresentationOffset` property stored at `lyrics.presentationOffset.v1`. Its read sites include the playback presentation clock and shared offset control. Its write sites include that control and the V3 reset button. Main V3/fullscreen and floating desktop reuse the same global setting. No editor-specific offset scope exists at baseline.
4. On track change, `LyricsSessionController.begin` clears the active version ID before stored-load/search completion. Persisted loads, manual adoption and explicit version selection later update the session version ID under identity/revision guards. The offset currently has no corresponding track/version scope transition.

No product source or test has been changed in this checkpoint. The focused O1 baseline contracts and post-change evidence will be recorded below after they are run.

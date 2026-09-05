# Ruby correction and follow-ups — 2026-09-06

Active branch: codex/lyrics-search-ambient-fix. Parent preview 6480455; local reversible checkpoint6498c03 before production edits. Checkpoint push restored successfully; origin matches6498c03 before this batch. Formal root user changes untouched.

## Verified ruby correction

- Click only ruby annotation, edit kana, save a new manual kana reading version and adopt it. Original lyrics/timings/previous versions unchanged; song-scoped dictionary persists correction through regeneration. Kana and romaji projection update together.
- Input accepts kana (katakana normalized), rejects Latin/empty/Han/digits. No unrestricted whole-line ruby from unaligned provider fallbacks. Partially unresolved affected lines fail with an edit-line explanation.
- Editor snapshots song/lyrics/reading version identity; stale edits reject. Projection revision now advances when projection changes, fixing saved-but-stale playback display cache. Explicit manual current version wins on reload regardless of preferred representation; local current flags reconciled after saving.
- Pure regression: `bash Tests/ruby_correction_contract.sh` PASS: 身体/からだ, other-song isolation, original input unchanged, provider あたし preserved, no unaligned whole-line ruby, kana/romaji/timestamp projection, dictionary persistence, invalid inputs.
- `bash Tests/phase_2_6c_runtime_contract.sh` PASS (includes engines); `bash Tests/phase_2_6a_persistence_contract.sh` PASS.
- Native fixture `python3 Tools/experience_visual_host/build.py`; `python3 Tools/experience_visual_host/run.py --surface main --style stage --ruby-correction --ruby-save-contract --output /tmp/ruby-contract-final.png`: RUBY_SAVE_CONTRACT_PASS. Uses temporary SQLite/UserDefaults. Verifies saved manual version, playback projection cache, reload, second-save/recommended selection, preserved old lines, stale song/reading rejection. Logs /tmp/ruby-save-contract-final.log.
- Native CUA: clicked 身体 annotation, entered からだ, saved; slider stayed18sec (no row seek). Initial run exposed DB nonblank-line rule and stale display cache; both fixed and native fixture rerun passed, screenshot showsからだ/karada. No real-user lyric edit or seek for tests.
- Independent review found alignment/selection/stale snapshot issues above; fixes applied.

## Authorized follow-ups

Version picker includes Edit Current Lyrics; ellipsis directly opens Settings. Recent plays exact-start timestamp/per-occurrence duration and no stale-snapshot double-counting; stats start with20songs plus Show More. Library now consolidates matching Spotify recordings with ≤1sec duration drift non-destructively; full-family detail/export/search retains all versions. Search covers all saved text layers and kana-derived romaji. Library identity/search, library revisions, listening history and statistics contracts PASS. Integrated Debug build PASS (`xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-ruby-integrated CODE_SIGNING_ALLOWED=NO build`). Legacy track_identity_v4_persistence harness lacks history/statistics source dependencies and cannot compile; new identity fixture covers the changed behavior. Historical lost occurrences cannot be reconstructed; additional visual/copy/portrait round follows only after current data verification.

# Library content revisions — 2026-09-06

User intent: editing an existing lyric creates a new independent version while retaining the original.

## Delivered behavior

- Each lyrics version has 编辑为新版本. The draft is bound to that stored song/version, independently of current Spotify playback.
- Edit lyric text/start seconds; add/remove rows. Unchanged drafts cannot save. Validation errors keep the draft open. Saving freezes controls and creates a new UUID with parent linkage; source content and original timestamps stay intact.
- Saving from the library preserves current adoption. Use 设为当前 on the revision or original to choose; playing-song adoption also updates playback.
- Schema 9 stores explicit preference separately from locks, confidence and timestamps. Normal editor and confirmed alignment saves retain their existing adoption behavior.
- Asset packages optionally carry preferredLyricsVersionID. Older packages remain readable; existing local preference wins, including redirected identities.
- Changed text clears stale reading fields; timing changes clear hidden end times. Translation attachments and word timing are not copied into an edited revision. Original attachments remain available on the original.

## Verification

All passed:

```sh
bash Tests/lyrics_editor_contract.sh
bash Tests/library_revisions_contract.sh
bash Tests/personal_data_package_contract.sh
bash Tests/sqlite_persistence_contract.sh
bash Tests/alignment_persistence_contract.sh
bash Tests/listening_statistics_contract.sh
bash Tests/production_database_upgrade_contract.sh
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build
```

New regression first failed on explicit original selection losing to a locked/high-confidence version, then passed. Covers fork/original preservation, no-op rejection, switch/reopen, wrong identity, regular editor adoption, partial timing, export/import and redirected-key preference. Independent review found no remaining blockers.

User database copy v8→v9: original column values unchanged, integrity ok, no foreign-key errors. New preview launched against the real database after a separate prelaunch backup: schema 9, integrity ok, zero FK errors; all 479 prelaunch lyric versions and 22,702 lyric rows retained with original values. No synthetic lyrics were saved into user data.

Native launch succeeded and showed the player/lyrics. Further editor interaction could not be verified: CUA repeatedly returned stale menu state and then screenshot unavailable. Full save/cancel UI acceptance remains pending; persistence was verified in isolated fixtures. Do not claim native editor acceptance or full-app correctness.

## Delivery boundary

Formal root /Users/apple/backup/sptifylyrics remains untouched. Implementation is on codex/experience-restoration in /private/tmp/spotifylyrics-experience-restoration-20260905, not merged to main. Preview: /Users/apple/Downloads/LyricsQ-library-revisions-20260906/SpotifyLyrics-library-revisions.app. BUILD_INFO alongside preview records final SHA, commands and evidence; user acceptance pending.

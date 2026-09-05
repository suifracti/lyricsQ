# Production database upgrade repair — 2026-09-05

## Failure and cause

Native statistics showed “无法读取听歌统计，请重试。”; library showed SQLite error (1). Read-only inspection of the user's formal Application Support DB found user_version=5 and no listening_history_sessions, reading_versions, or lyrics_timing_versions. Legacy repository policy permitted migrations on disposable copies but prevented the production path from reaching v6–v8. Fresh-DB-only tests had missed this.

User explicitly authorized repairing the real database and auditing the related features. Formal Git checkout /Users/apple/backup/sptifylyrics remains untouched; implementation lives in /private/tmp/spotifylyrics-experience-restoration-20260905, branch codex/experience-restoration.

## Change

Repository startup now applies the same forward migrations to existing and fresh databases, and requires currentVersion before publishing prepared state. Every existing lower-version DB must first obtain a consistent sqlite3_backup snapshot. The snapshot includes committed WAL pages, uses DELETE journal mode for standalone recovery, closes before atomic publication, and cleans temporary files/sidecars on failure. Backup failure aborts migration. Existing migration transactions and future-schema refusal remain intact.

v6 imports traceable legacy reading attachments without rewriting lyric_lines; v7/v8 add timing/history tables. Failed versions roll back and retry starts from the last committed version. No fabricated past listening history is inserted.

## Tests and evidence

- `bash Tests/production_database_upgrade_contract.sh`: PASS. Isolated CFFIXED_USER_HOME exercises the actual default Application Support path. Original test failed specifically because default-path schema stayed v5. Final tests cover locked/manual lyrics, kana/romaji, a pinned WAL reader, a standalone readable backup, and repeated opening without another backup.
- Its Python matrix covers v3–v8, original-column row equality, integrity and foreign keys, failed migration rollback/retry, failed backup refusal/retry, and specifically unsupportedSchema for v999.
- `bash Tests/listening_statistics_contract.sh`: PASS.
- `bash Tests/listening_history_contract.sh`: PASS, including write-lock error/retry.
- `bash Tests/sqlite_persistence_contract.sh`: PASS.
- `bash Tests/timing_persistence_immutable_contract.sh`: PASS, including immutable/idempotent timing and conflict rejection.
- `bash Tests/personal_data_package_contract.sh`: PASS.
- `bash Tests/phase_2_6a_persistence_contract.sh`: reading persistence checked on current schema. Stale harnesses were repaired to include their required model sources; the reading test's hard-coded v6 assertion was replaced with currentVersion. Assertions of reading behavior remain.

Two copies of the user's v5 DB were upgraded separately, including the final implementation. Every original table's rows matched its pre-upgrade fingerprint, and integrity/foreign-key checks passed. Real DB upgrade occurred only after final-copy validation and successful builds.

## Native and real-data audit

- Automatic production recovery backup matches every row of the prelaunch SQLite snapshot.
- Production DB now reports schema 8, integrity_check=ok, zero foreign-key violations.
- All 473 original lyrics_versions, 22,422 lyric_lines, 758 track_aliases and other existing lyric/translation rows remain unchanged after launch.
- Library now shows 322 local asset songs. First Love detail opens, showing both saved lyric versions and migrated reading versions.
- Recent playback loads the genuinely observed song.
- Statistics shows nonzero actual duration/session/song counts. All-time, 7-day, 30-day views and explicit refresh work.
- App restart retains existing session IDs and durations; refresh increases duration. The direct statistics toolbar button was successfully clicked after restart and opened the statistics tab.
- Playback continued naturally; no Spotify seek/track change, fixture adoption, or fabricated history was used. Earlier missing historical sessions cannot be reconstructed from this repair.

## Builds / delivery

Debug and Release BUILD SUCCEEDED:

```
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build
```

Opened preview: /Users/apple/Downloads/LyricsQ-database-upgrade-20260905/SpotifyLyrics-database-upgrade.app. BUILD_INFO.md and evidence hold source identity, hashes and logs. No main merge, release tag or accepted-build archive.

Independent read-only review found no blocking defects. Its suggestion to avoid publishing incomplete backup files was implemented and tested. This audit covers the repaired persistence path and the three related tools; it does not claim exhaustive validation of unrelated app features.

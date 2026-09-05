# Title-only recovery repair — 2026-09-05

Implementation tree: `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/experience-restoration`. Base `b3cc68c0552e61ea1b806a7284cbe2c8f721f7d3` plus the three lyric-search production changes and dedicated tests in this commit. Not merged into main. Formal project `/Users/apple/backup/sptifylyrics` remains untouched.

## Behavior

Read-only LRCLIB requests returned zero results for Marigold + 愛繆, while title-only search returned Aimyon records. SearchManager had restored an intentionally omitted artist, LRCLIB had constrained free-text queries with structured filters, and exact-title scoring prevented a manual candidate exception from applying. These paths are repaired. Original playback identity and independent ID-conflict rejection remain intact. Manual title matches may be candidates; this does not confirm an artist alias or enable automatic cross-artist adoption.

## Verification

- Behavioral red: manager artist omission, provider request shape and manual candidate matcher failed before the production changes.
- `bash Tests/title_only_recovery_contract.sh`: PASS (generated fixtures, no database).
- `bash Tests/title_only_recovery_contract.sh live`: PASS; real production provider/manager returned 11 Marigold/Aimyon candidates, including approximately 307 seconds. Metadata only recorded, no lyrics persisted.
- `bash Tests/query_identity_contract.sh`: PASS.
- `bash Tests/phase_2_11a_retrieval_contract.sh`: PASS.
- `bash Tests/japanese_alias_contract.sh`: PASS.
- Independent production review: no actionable findings.
- Debug: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build`: BUILD SUCCEEDED.
- Release: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build`: BUILD SUCCEEDED.
- Production source hashes rechecked against pre-build manifest before packaging.

Legacy `bash Tests/real_track_lyrics_contract.sh` did NOT pass: its existing compile arrays omit TTMLParser, then listening history/statistics models. A temporary TTML source-list repair allowed core/local/LRCLIB portions to pass, but was withdrawn after the next baseline failure; the harness is unchanged in this commit. Its PlaybackState fixture was not executed (compilation failed earlier). Broader suite remains unverified; no fixture used the user database.

## Preview

`/Users/apple/Downloads/LyricsQ-search-recovery-20260905/SpotifyLyrics-search-preview.app` was copied from the verified Release output and opened after quitting the old preview. This is an unaccepted preview, not a release/archive.

Native UI observation: user had switched from Marigold to back number ハッピーエンド and was playing it. New app connected and displayed that song's lyrics. We preserved that playback; native Marigold candidate selection is still pending, while its live search is verified. No candidate was adopted by the agent. Full-background stage correction remains included.

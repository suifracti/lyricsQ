# Expanded lyric sources and provenance — 2026-09-06

This iteration follows the user's request to identify lyric-version sources and add usable international sources, referencing Lyrics-Plus. Active implementation is the preserved feature worktree `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/lyrics-search-ambient-fix`, based on checkpoint `d18ff36f0c106056f3786b07bfca7ff51c2e8f93`. Formal user checkout `/Users/apple/backup/sptifylyrics` remains untouched. No main merge.

## Behavior

- Added lyrics.ovh (international plain-text fallback), Kuwo and Kugou (experimental real LRC/line timestamps). Together with AMLL, LRCLIB, NetEase and QQ, seven network providers exist; local files/database and browser-only discovery are not counted as extra online lyric bodies.
- lyrics.ovh returns only a body; its title/artist are query echoes, never independent matching evidence. SafeMatcher keeps nonempty results visible for manual confirmation and prevents automatic adoption, even if a future provider accidentally returns `.match`.
- Kuwo/Kugou preserve actual catalog metadata, use returned record identifiers for lyric fetches and never copy query Spotify IDs/ISRC into evidence. No estimated word timing, translation or fabricated timestamps. Bounded serial body chains, response sizes, cancellation and explicit network/HTTP failures.
- New sources migrate once into old configurations; previously disabled providers remain disabled. Explicitly disabling a new provider survives normalization/reload. Standard mode allows lyrics.ovh and blocks all four experimental providers before construction.
- Online search fan-out is bounded to three active providers; local providers still run first and automatic preference follows configured order, not response speed. Fixed a reproduced cancellation race where a completed success buffered before cancellation could still be adopted.
- Both version pickers show friendly source labels and explicit provenance, retaining custom names and notes. Manual revision ancestry is followed through immutable parent IDs; unknown/missing ancestry is disclosed. Unknown historical raw source IDs remain stored, no destructive migration.

## Verification

Fresh focused contracts passed:

```sh
bash Tests/lyrics_ovh_provider_contract.sh
bash Tests/kuwo_provider_contract.sh
bash Tests/kugou_provider_contract.sh
bash Tests/lyric_source_provenance_contract.sh
bash Tests/provider_expansion_configuration_contract.sh
bash Tests/search_concurrency_manual_contract.sh
bash Tests/piano_search_contract.sh
bash Tests/amll_provider_contract.sh
bash Tests/v3_lyric_readability_contract.sh
```

Tests cover URL encoding, actual versus query metadata, body limits, malformed data, HTTP errors/timeouts/cancellation, real timings, bounded requests, temporary SQLite ancestry/reload, unknown provenance, migration/disable/mode policy, concurrent peak/priority/local-first and the reproduced cancellation race (red before fix, green after).

Actual production provider classes were also compiled into a temporary read-only Swift health harness and queried once per source (no user database or playback): lyrics.ovh Coldplay/Yellow returned one candidate,41 plain lines in2.23s; Kuwo 稻香/周杰伦 returned3 candidates,first50 timed lines in0.96s; Kugou same query returned3 candidates,first53 timed lines in1.05s. Full lyrics and transient download keys were not logged. These are point-in-time health results, not catalog-wide coverage guarantees.

Native isolated host with `--source-provenance --timed --ruby-display` verified the real version sheet shows 网易云音乐 and 来源：网易云音乐. Settings showed all seven online providers; switching to standard mode disabled NetEase/QQ/Kuwo/Kugou while retaining lyrics.ovh. Fixture uses temporary database/defaults and generated lyrics/artwork. No production playback seek performed.

Debug, Release and isolated native host builds passed:

```sh
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-expanded-sources-debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-expanded-sources-release CODE_SIGNING_ALLOWED=NO build
python3 Tools/experience_visual_host/build.py
```

Independent read-only integration review found no blocking issue; project lint and `git diff --check` passed. Release delivery result is recorded alongside the preview in BUILD_INFO.md.

## Limits

Musixmatch anonymous endpoint could not establish TLS on this network, so it is not shipped/countable as a working source. Lyrics-Plus has multiple same-name projects; the macOS afeibukaixin/Lyrics-Plus provider registry was the best match to the description, not a confirmed Bilibili video identity. Lyrics.ovh is unsynchronized; Kugou/Kuwo currently add line timing, not KRC word decoding. True word highlighting still requires real saved word spans (shared renderer verified in preceding reports), not every retrieved song has them. Provider availability may change.

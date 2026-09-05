# Current-song search and ambient correction — 2026-09-06

## Scope and source

Formal root: `/Users/apple/backup/sptifylyrics` remains protected with its prior user changes. Implementation: `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/lyrics-search-ambient-fix`, based on main `54a73a271d8950beb8cbbec888c232c8966d039d`. Checkpoint `1e1227080942f558f5f98d6cfa96643e4ff2d3ad` was pushed before production edits. No playback seeking, lyric adoption, database rewriting, or source recovery.

## Findings and resulting behavior

Runtime song was stb《アーカイブ - Piano Ver.》, Spotify ID `5O45JO2bYhtyah2flZ9TI0`. QQ returned an original-arrangement candidate with 72 untimed lines, but `stb;NEA;ささ。` was treated as one primary artist. Semicolons now delimit provider artist lists, preserving slash names such as HUNTR/X. Explicit piano suffixes are stripped for controlled search and retained as version evidence. Raw Japanese spelling accompanies the normalized fallback. Matching original titles can yield selectable candidates; piano/original differences never auto-adopt. Independent ID and artist conflicts still reject. Both candidate row surfaces show a readable piano-arrangement warning.

Ambient opacity previously multiplied by the blur setting, hiding the image at zero. The cached full-resolution snapshot now retains fixed opacity while diffusion increases from 0 to 48 points. Album palette/glow and foreground artwork remain. Classic left/right splits replace the Divider with the spacing already budgeted by the responsive column calculation. Preset names reflect increasing softness.

## Evidence

- Red regression: `bash Tests/piano_search_contract.sh` failed on candidate recovery before source fix.
- `bash Tests/piano_search_contract.sh`: PASS; original arrangement candidate-only, exact piano version eligible for auto-tier, different artist/Spotify ID reject, raw Japanese fallback, Piano Man preserved, user notice present.
- `bash Tests/piano_search_contract.sh live`: PASS; QQ manager returned `アーカイブ|stb;NEA;ささ。|72 lines`, no adoption or production data writes.
- `bash Tests/query_identity_contract.sh`: PASS.
- `bash Tests/japanese_alias_contract.sh`: PASS.
- `bash Tests/title_only_recovery_contract.sh`: PASS.
- `bash Tests/v3_background_composition_contract.sh`: PASS.
- `bash Tests/v3_ambient_backdrop_contract.sh`: PASS.
- `bash Tests/v3_lyric_readability_contract.sh`: PASS.
- Debug: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-search-ambient-deriveddata CODE_SIGNING_ALLOWED=NO build`: PASS.
- Isolated native fixture built with `python3 Tools/experience_visual_host/build.py`; run.py ambient square at `--blur 0` and `--blur 100`, classic square. CUA native screenshots verified visible clear background at zero and diffuse color at 100, crisp foreground cover, no classic center divider. The fixture cacheDisplay PNGs omit compositor blur and must not be treated as blur-endpoint evidence. CUA screenshot is the visual evidence for diffusion. No GPU timing/performance claim.
- Independent static review found no actionable issue in matcher/background/layout changes.

## Limits

The live recovered lyrics are original-arrangement, untimed content, not a verified synchronized piano transcription. Preview selection is left to the user. Native atmosphere and interaction remain subject to user acceptance; no competitor-equivalence claim. This task stays on its feature branch until a separate merge.

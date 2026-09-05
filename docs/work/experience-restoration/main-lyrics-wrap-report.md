# Main lyric wrapping — 2026-09-05

User approved main-window width-adaptive wrapping, with original lyric identity/timing/seek and attached reading/translation layers retained. Desktop and capsule presentations are unchanged.

The V3 renderer already used wrapping Text, CoreText timed multiline layout and ruby flow. This patch removes additional font shrinking based on character count, removes auxiliary two-line truncation, and gives the row an explicit readable-width proposal plus unbounded vertical sizing. Existing language-aware line breaking is reused; lyric records and timings are not split or rewritten. The row-level seek button is unchanged.

Checks: multiline layout contract (including cross-line spans and explicit newline), timed layout precision, V3 long ruby wrap and V3 lyric readability passed. The final build and native preview boundaries are recorded in BUILD_INFO.md with the source identity. No user database fixture was used.

`bash Tests/timed_multilayer_presentation_contract.sh` also passed. Full commands for other tests: `bash Tests/multiline_layout_contract.sh`, `bash Tests/timed_layout_precision_contract.sh`, `bash Tests/v3_long_ruby_wrap_contract.sh`, `bash Tests/v3_lyric_readability_contract.sh`.

Debug and Release BUILD SUCCEEDED: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build`, and Release with `/tmp/lyrics-experience-delivery-release`. Source manifest verified after builds.

New preview `/Users/apple/Downloads/LyricsQ-lyric-wrap-20260905/SpotifyLyrics-lyric-wrap.app` opened successfully. Native S.S.S. plain lyrics with kana were inspected and scrolled without visible overlap. A narrow-window drag failed with computer-use windowNotFoundAtPosition; a native zoom toggle and reverse succeeded. Playback moved to another song with candidates before a long wrapped synchronized line could be fully inspected. Therefore full native narrow-window and live timed-wrapping acceptance remains pending; timing/wrapping claims rely on the passing dedicated contracts. No candidate adopted, no lyric seek or playback command sent.

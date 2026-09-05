# Complete stage cover — 2026-09-05

User correction supersedes the previous aspect-fill stage acceptance: the original artwork must always be complete. This change only adjusts the background and its relevant controls; lyrics remain unchanged.

The original is centered at the largest aspect-fit size. A separate blurred duplicate fills unused background space. Persisted stage zoom/position values cannot crop or move the original, and those controls are hidden for stage. Blur now affects only the extension. Ambient and classic retain their behavior.

Geometry validation covers four wide/tall window sizes and five image proportions from 0.2 to 5, checks containment, original proportions, centering, maximum fitted size, saved zoom/position independence and unchanged lyric reading geometry. The updated test failed on the previous crop implementation before the fix, then passed.

Passed commands:
- `bash Tests/v3_responsive_geometry_contract.sh`
- `bash Tests/v3_artwork_presentation_contract.sh`
- `bash Tests/v3_artwork_resolution_contract.sh`
- `bash Tests/v3_lyric_readability_contract.sh`
- `git diff --check`

Build and native preview results are recorded in the delivered BUILD_INFO.md. No user database fixtures or playback commands are used for these checks. No image generation, source-image editing, or stretching is involved.

Debug and Release both returned BUILD SUCCEEDED using `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration <Debug|Release> -derivedDataPath <path> CODE_SIGNING_ALLOWED=NO build`; paths respectively `/tmp/lyrics-experience-integration-deriveddata` and `/tmp/lyrics-experience-delivery-release`. Source manifest was verified unchanged after builds.

New preview `/Users/apple/Downloads/LyricsQ-complete-cover-20260905/SpotifyLyrics-complete-cover.app` opened successfully. Native screenshot of ハッピーエンド showed the entire square artwork centered, including bottom album lettering, with blurred side extensions. Other aspect ratios are geometry-contract evidence, not claimed native screenshots. User started interacting with the app, so further UI actions were stopped. No playback command was sent.

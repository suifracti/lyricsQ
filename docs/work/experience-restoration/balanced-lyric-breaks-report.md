# Balanced lyric breaks — 2026-09-05

User reported isolated short tails in long Japanese lyrics. The old character-count breaker inserted approximate breaks; native Text could wrap those rows again. Main V3 now measures the rounded display font and balances the minimum number of rows, preferring word boundaries and penalizing leading punctuation/particles. Plain and timed original rows share ranges; original UTF-16 offsets, authored line delimiters, and timing projection are preserved. Inline ruby retains its separate flow. Desktop/capsule and window proportions are unchanged.

Candidate widths are bounded before CTLine allocation; plain results use a 256-entry cache. Paragraphs over 256 characters fall back to native greedy breaking. This is an experimental preview, not a universal linguistic segmentation guarantee.

## Verification

PASS: `bash Tests/balanced_lyric_breaks_contract.sh` (screenshot phrases and English, widths 420/600/680/740/860, exact source preservation, measured fit, balanced tails, plain/timed agreement, authored delimiters).

PASS: `bash Tests/multiline_layout_contract.sh`, `bash Tests/timed_layout_precision_contract.sh`, `bash Tests/v3_lyric_readability_contract.sh`, `bash Tests/timed_multilayer_presentation_contract.sh`.

Debug and Release BUILD SUCCEEDED:

```
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build
```

Final production hashes match `/tmp/balanced-breaks-manifest.json`. Actual-font proof of three screenshot phrases was rendered at 600 pt and visually inspected. It is a typography fixture, not a live screenshot of the original song. A local optimized 216-character Japanese microbenchmark across five uncached widths took approximately 0.080 seconds; not a whole-app performance guarantee.

New Release preview: `/Users/apple/Downloads/LyricsQ-balanced-lyrics-20260905/SpotifyLyrics-balanced-lyrics.app`. Opened through native UI; current playback had advanced to 幽霊になって. Original screenshot song was not replayed or injected into the user database. Evidence and source identity accompany the preview. No merge to main or accepted release archive.

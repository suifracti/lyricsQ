# Cover stage correction

User explicitly confirmed that the album cover is the full stage background with lyrics on it. The prior complete-cover card and separate lyric region misunderstood that instruction and are superseded. Ambient/classic and all reliability/desktop/capsule changes remain intact.

## Implementation

Aspect-fill cover geometry covers the full canvas at all zoom settings, retaining image proportions and naturally cropping edges when the image and window differ. Position changes the background crop; no cover card, reserved empty cover space, or lower lyric strip remains. The shared lyrics viewport overlays the center of the stage; the existing bottom HUD also sits on the same cover. A mild full-canvas veil and text shadow support contrast. Background zoom/softening/crop controls are labeled accordingly. Removed stage-only current-verse projection and cover-aspect callbacks; preview keeps shared document scrolling.

## Checks

- Red: revised production geometry test failed with `cover must fill the entire stage, including behind lyrics` on the previous implementation.
- Green: 60 cover orientation/window/position combinations verify full coverage, aspect preservation and a tall overlay reading area independent of cover orientation.
- Passed: `bash Tests/v3_responsive_geometry_contract.sh`, `bash Tests/v3_background_composition_contract.sh`, `bash Tests/v3_artwork_presentation_contract.sh`, `bash Tests/v3_cover_layout_contract.sh`, `bash Tests/v3_lyric_readability_contract.sh`, `bash Tests/v3_lyrics_scroll_stability_contract.sh`, `bash Tests/v3_visual_tuning_reactivity_contract.sh`. An initial convenience runner used the wrong tuning-script name; the correctly named existing script passed separately.
- Native isolated host build passed. Generated-fixture images `stage-overlay-wide.png` (1152×720 square cover), `stage-overlay-compact.png` (760×552 landscape), and `stage-overlay-bright.png` (760×1000 bright square cover) were inspected: cover extends behind lyrics and HUD to the whole canvas; current verse remains readable. These replace old stage acceptance images and are not real Spotify evidence.
- Independent read-only review found no actionable correctness regression; specifically checked ambient/classic scope and shared search-preview path.

Production build commands/logs and exact delivered source are recorded in the new preview BUILD_INFO.md. This correction changes the product definition; earlier green geometry tests proved the wrong composition and must not override the user's direction.

Production Debug and Release builds passed with `CODE_SIGNING_ALLOWED=NO`, using `/tmp/lyrics-experience-integration-deriveddata` and `/tmp/lyrics-experience-delivery-release` respectively. Logs are in the new package evidence directory. Package: `/Users/apple/Downloads/LyricsQ-stage-background-20260905/SpotifyLyrics-stage-preview.app`. Production source matches the native fixture manifest exactly.

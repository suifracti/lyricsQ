# Quiet toolbar — 2026-09-05

User approved simplifying the upper-right toolbar to window mode, search and More, including a visual update. This preserves freely resizable windows, background and lyrics layouts.

Three 36-point buttons share a translucent capsule, subtle border/shadow, Chinese help/accessibility labels, and hover/pressed feedback. Window mode uses an explicit popover rather than a native borderless menu button. More groups existing current-song/lyric operations, appearance, settings and provider recovery. Nested pages return to More without losing the underlying controls. Legacy settings shortcut used by another layout remains intact.

Native first-pass verification exposed the existing three-second timer hiding the toolbar even with a stationary pointer at its top edge. The final change tracks pointer presence and prevents timer dismissal while either the pointer or a popover is active. Moving away with no open panel still hides it. Independent read-only review found no actionable issues, including the follow-up timer fix.

Five existing contracts passed: `bash Tests/v3_visual_polish_contract.sh`, `bash Tests/v3_responsive_ui_finish_contract.sh`, `bash Tests/v3_artwork_presentation_contract.sh`, `bash Tests/v3_lyric_readability_contract.sh`, `bash Tests/settings_contract.sh`. `git diff --check` passed. The first Debug compile identified a shared preferencesButton used outside the toolbar; it was retained and subsequent builds passed. No user database fixtures were used.

Final build commands: `xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build`; Release uses `/tmp/lyrics-experience-delivery-release` with `-configuration Release`. Package BUILD_INFO.md records exact source, hash, final outcomes and native verification.

Final Debug and Release both BUILD SUCCEEDED; source manifest verified unchanged after build. Final preview opened at `/Users/apple/Downloads/LyricsQ-quiet-toolbar-final-20260905/SpotifyLyrics-quiet-toolbar.app`. Native screenshot confirmed the short three-icon surface without the old blue menu label. More root, appearance page, return navigation, current-song operations, and window-mode popover all opened successfully. Popovers and toolbar remained visible across checks lasting more than three seconds. No mode switch, lyric adoption or playback command was sent.

Search-button native verification was interrupted by the computer-use capture service failing with ScreenCaptureKit -3811, including the follow-up state read. The search route is retained and compiled, but final native search opening/keyboard checks are not claimed passed. This limitation is tooling evidence, not a demonstrated application failure.

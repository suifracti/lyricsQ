# Local version names and notes — 2026-09-05

User asked to add one customization and retain a way back to the original. Implemented the first proposal: names and notes for lyrics/translation/reading/timing version headings. Each pencil opens drafts with Save, Cancel and Restore Default. Original heading remains visible when renamed. Restore clears both local annotations immediately; source content, asset UUID, provenance, selected/current status, locks and DB schema are untouched.

Storage is per-kind/per-version UUID AppStorage in local app preferences. It is explicitly labeled local-only and is not included in asset exports. This is presentation customization, not lyric editing or a version rollback feature.

Debug and Release BUILD SUCCEEDED:
```
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-experience-integration-deriveddata CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Release -derivedDataPath /tmp/lyrics-experience-delivery-release CODE_SIGNING_ALLOWED=NO build
```

Native Release validation on Don't Stop The Bus: pencil opened editor; entered temporary name and note; Save displayed both while retaining original QQEXPERIMENTAL and adoption status. Reopened, edited name, cancelled: saved annotation remained. Reopened and Restore Default: original heading returned, note disappeared, other version stayed unchanged. Temporary verification annotations were fully reset. Actual screenshot inspected for baseline button layout. Translation/timing use the same component and compile; no matching live assets were modified for separate UI tests.

Opened preview: /Users/apple/Downloads/LyricsQ-version-labels-20260905/SpotifyLyrics-version-labels.app. Formal user checkout untouched; feature branch only, no main merge. No database migration for this change.

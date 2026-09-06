# Click the displayed kana to correct a song reading

User-approved design: click the ruby annotation (not original Han text), edit kana, save a new manual reading version; preserve original, update kana/romaji together, remember a song-scoped correction through regeneration.

Continue active preview branch from 6480455; formal root remains protected. This checkpoint precedes production changes.

1. Add scoped correction validation and regression fixtures: 身体/からだ, other-song isolation, regenerated kana/romaji, invalid input, original/version preservation.
2. Reuse ReadingUserDictionary and ReadingSessionController to save a new manual kana version before remembering the scoped rule. Guard revision/track changes and surface matching. Use existing current reading as baseline when available; preserve unrelated lines/tokens.
3. Add an annotation-only interaction in RubyLineView and an editor sheet hosted by the V3 main window. Avoid nested row buttons: original text retains seek action, annotation tap opens editor only. Report errors without closing unsaved edits; dismiss stale editor on track changes.
4. Run focused regression, Debug/Release, native click/close check without changing user playback, independent review, then commit/push and open a unique preview. Document verification limits and source SHA.

## User follow-ups, authorized in order

After ruby correction: combine lyric version selection and lyric editing in the same panel; change the ellipsis control to directly open Settings. Then make Recent Plays one immutable/separate row per playback occurrence with concrete start time and per-occurrence listened duration (no overlap/cumulative labels), expand statistics song list, consolidate duplicate library song rows created by lyric-version edits/switches, and search library by original lyrics/kana/romaji/translation as well as song metadata. User clarified duplication specifically follows editing/switching versions, not changing song metadata. Keep all versions and original assets.

After the data/library batch: integrate transport controls + title/artist/album into all three visual modes, especially stage bottom right; provide both selection-based and full-lyrics copy; improve portrait responsiveness for ambient and classic (stage composition preserved). User authorizes trying a cohesive design. Do not replace/crop the full stage cover or lock window aspect ratio.

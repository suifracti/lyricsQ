# Click the displayed kana to correct a song reading

User-approved design: click the ruby annotation (not original Han text), edit kana, save a new manual reading version; preserve original, update kana/romaji together, remember a song-scoped correction through regeneration.

Continue active preview branch from 6480455; formal root remains protected. This checkpoint precedes production changes.

1. Add scoped correction validation and regression fixtures: 身体/からだ, other-song isolation, regenerated kana/romaji, invalid input, original/version preservation.
2. Reuse ReadingUserDictionary and ReadingSessionController to save a new manual kana version before remembering the scoped rule. Guard revision/track changes and surface matching. Use existing current reading as baseline when available; preserve unrelated lines/tokens.
3. Add an annotation-only interaction in RubyLineView and an editor sheet hosted by the V3 main window. Avoid nested row buttons: original text retains seek action, annotation tap opens editor only. Report errors without closing unsaved edits; dismiss stale editor on track changes.
4. Run focused regression, Debug/Release, native click/close check without changing user playback, independent review, then commit/push and open a unique preview. Document verification limits and source SHA.

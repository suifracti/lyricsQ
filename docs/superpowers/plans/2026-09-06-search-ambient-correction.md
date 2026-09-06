# Current-track search and backdrop correction

User reports アーカイブ - Piano Ver. / stb has no lyrics; ambient at zero is black and higher values look clearer; classic divider is unwanted.

Evidence: runtime QQ returns アーカイブ, artist stb;NEA;ささ。, 72 lines, then manager returns noMatch. Shared artist tokenizer does not recognize semicolon provider separators. Piano Ver. is not a known version marker. Verify matcher and query variants with a fixture; surface related arrangement versions only as explicit candidates, never silently replace piano timing with original timing. Inspect live provider result after fix.

Ambient currently multiplies artwork opacity by normalized blur, so zero hides imagery. Use a continuous, visible artwork field at all values; only diffusion increases with slider. Preserve album-derived color/soft light and readable veil without a flat black endpoint. Remove classicDivider; retain deliberate gap between columns and free window resizing.

Run matching/query regressions, existing background/readability checks, Debug/Release; native current-track and visual inspection. Do not change selected lyrics without user adoption or generate fake lyric data. Preserve the formal dirty root. Base main54a73a2; task branch codex/lyrics-search-ambient-fix.

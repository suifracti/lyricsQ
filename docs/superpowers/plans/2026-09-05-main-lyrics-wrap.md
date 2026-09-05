# Main lyrics automatic wrapping

User approved width-adaptive wrapping in the main window, keeping each lyric's identity, timing/highlight and seek. Preserve desktop and capsule behavior. Existing Text/CoreText/ruby flow engines already wrap; remove V3 long-text font shrinking and auxiliary two-line truncation, and make the row's width proposal explicit so height expands with all text layers. Reuse existing line-break/timed layout machinery rather than splitting stored lyric records.

Validate multiline, fine timing and ruby contracts plus readability/builds. Use native preview for current long lines where available; do not persist generated lyric fixtures in the user database.

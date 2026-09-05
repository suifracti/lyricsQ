# Balanced lyric breaks

User rejected isolated short tail lines in screenshot. Root cause: plain V3 breaker estimates character widths and inserts hard breaks, then SwiftUI wraps those again. Replace with actual-font measured balanced line ranges. Preserve explicit authored newlines. Prefer language token boundaries, discourage tiny tails and leading punctuation/particles, and keep text/time ranges intact. Opt into the same range policy for V3 timed rows only; desktop/capsule remain unchanged.

Test the screenshot's three exact sentences, English words, explicit newlines and timing coverage before final build/native delivery. Do not claim semantic understanding beyond token-boundary heuristics.

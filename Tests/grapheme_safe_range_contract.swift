import Foundation

@main
struct GraphemeSafeRangeContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() {
        // Test 1: Standard Japanese lyric line
        let text1 = "思っている"
        // UTF-16 count: 思(1) っ(1) て(1) い(1) る(1) = 5
        let spans1 = [
            TimedTextSpan(id: 0, text: "思って", trailingWhitespace: "", startTime: 0, endTime: 1.0, utf16Start: 0, utf16Length: 3),
            TimedTextSpan(id: 1, text: "いる", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 3, utf16Length: 2)
        ]
        let line1 = LyricLine(timestamp: 0, originalText: text1, timedSpans: spans1)
        guard let resolved1 = line1.resolvedGraphemeSpans() else {
            print("FAIL: line1 grapheme resolution returned nil")
            exit(1)
        }
        assertRule(resolved1.count == 2, "Expected 2 resolved spans")
        assertRule(resolved1[0].text == "思って", "Span 0 text mismatch")
        assertRule(resolved1[1].text == "いる", "Span 1 text mismatch")
        assertRule(text1[resolved1[0].range] == "思って", "Span 0 range substring mismatch")
        assertRule(text1[resolved1[1].range] == "いる", "Span 1 range substring mismatch")

        // Test 2: Grapheme clusters with Combining Dakuten
        // "が" composed of "か" (U+304B) + combining dakuten (U+3099)
        // In Swift, "か\u{3099}" is 1 Extended Grapheme Cluster Character, but 2 UTF-16 code units.
        let combiningKa = "か\u{3099}きく" // 3 Characters, 4 UTF-16 code units
        let spans2 = [
            TimedTextSpan(id: 0, text: "か\u{3099}", trailingWhitespace: "", startTime: 0, endTime: 1.0, utf16Start: 0, utf16Length: 2),
            TimedTextSpan(id: 1, text: "きく", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 2, utf16Length: 2)
        ]
        let line2 = LyricLine(timestamp: 0, originalText: combiningKa, timedSpans: spans2)
        guard let resolved2 = line2.resolvedGraphemeSpans() else {
            print("FAIL: line2 grapheme resolution returned nil")
            exit(1)
        }
        assertRule(resolved2.count == 2, "Expected 2 resolved spans for combining characters")
        assertRule(combiningKa[resolved2[0].range] == "か\u{3099}", "Combining character range mismatch")
        assertRule(combiningKa[resolved2[1].range] == "きく", "Combining character rest mismatch")

        // Test 3: Fail-Closed validation when UTF-16 splits an Extended Grapheme Cluster (Contract 4)
        // If an erroneous span splits between U+304B and U+3099 (utf16Length: 1 instead of 2):
        let invalidSpansSplitGrapheme = [
            TimedTextSpan(id: 0, text: "か", trailingWhitespace: "", startTime: 0, endTime: 1.0, utf16Start: 0, utf16Length: 1),
            TimedTextSpan(id: 1, text: "\u{3099}きく", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 1, utf16Length: 3)
        ]
        let lineInvalid = LyricLine(timestamp: 0, originalText: combiningKa, timedSpans: invalidSpansSplitGrapheme)
        assertRule(lineInvalid.resolvedGraphemeSpans() == nil, "Must fail-closed and return nil when grapheme cluster is split")

        // Test 4: Fail-Closed validation when UTF-16 offsets are out of bounds (Contract 4)
        let invalidSpansOOB = [
            TimedTextSpan(id: 0, text: "思って", trailingWhitespace: "", startTime: 0, endTime: 1.0, utf16Start: 0, utf16Length: 10)
        ]
        let lineOOB = LyricLine(timestamp: 0, originalText: text1, timedSpans: invalidSpansOOB)
        assertRule(lineOOB.resolvedGraphemeSpans() == nil, "Must fail-closed and return nil when spans are out of bounds")

        print("PASS: Grapheme safe range contract verified")
    }
}

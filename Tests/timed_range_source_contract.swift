import Foundation

@main
struct TimedRangeSourceContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() throws {
        let spans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 2.0, endTime: 3.0, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]

        // 1. 两个内容完全相同、但独立构造的 String value: spans 仅携带 UTF-16 offset，现场在当前 originalText 上重新 resolve
        print("[1] Testing independent String instance resolution with pure UTF-16 offsets...")
        let originalInstance1 = String("Hello World!".reversed().reversed()) // force separate allocation/buffer
        let displayInstance2 = String("Hello World!".map { $0 })
        let identicalSegments = TimedTextComposer.composeSegments(
            displayText: displayInstance2,
            originalText: originalInstance1,
            spans: spans,
            currentTime: 1.5
        )
        assertRule(identicalSegments.count == 4, "Expected 4 segments for 'Hello World!'")
        assertRule(identicalSegments[0].text == "Hello" && identicalSegments[0].isHighlighted == true, "Hello is highlighted at 1.5s")
        assertRule(identicalSegments[1].text == " " && identicalSegments[1].isHighlighted == false, "Space is unhighlighted at 1.5s")
        assertRule(identicalSegments[2].text == "World" && identicalSegments[2].isHighlighted == false, "World is unhighlighted at 1.5s")
        assertRule(identicalSegments[3].text == "!" && identicalSegments[3].isHighlighted == false, "! is unhighlighted at 1.5s")
        assertRule(identicalSegments.map(\.text).joined() == "Hello World!", "Full text reconstructed faithfully")

        // 2. displayText 被插入换行（如 line breaker 换行） → 安全退回，不越界、不错位、文本完整
        print("[2] Testing displayText with inserted newline from line breaker (safe fallback)...")
        let brokenDisplayText = "Hello\nWorld!"
        let brokenSegments = TimedTextComposer.composeSegments(
            displayText: brokenDisplayText,
            originalText: originalInstance1,
            spans: spans,
            currentTime: 1.5
        )
        assertRule(brokenSegments.count == 1, "Expected single fallback segment")
        assertRule(brokenSegments[0].text == brokenDisplayText, "Full broken display text must be preserved")
        assertRule(brokenSegments[0].isHighlighted == true, "Fallback text rendered cleanly")

        // 3. reading projection 改变文本（如 readingSurfaceText 拼音转换） → 不错误套用 original ranges
        print("[3] Testing reading surface projection changed text (safe fallback)...")
        let pinyinDisplayText = "hán lèi de yuán quān"
        let japaneseOriginal = "含泪的圆圈"
        let pinyinSegments = TimedTextComposer.composeSegments(
            displayText: pinyinDisplayText,
            originalText: japaneseOriginal,
            spans: spans,
            currentTime: 1.5
        )
        assertRule(pinyinSegments.count == 1, "Expected single fallback segment for reading projection")
        assertRule(pinyinSegments[0].text == pinyinDisplayText, "Display text faithfully preserved")

        // 4. combining-mark / emoji grapheme boundary validation
        print("[4] Testing combining-mark and emoji grapheme cluster boundaries...")
        // "e\u{301}" is "é" (2 UTF-16 code units = 1 grapheme cluster)
        let cafeText = "cafe\u{301}"
        let validCafeSpans = [
            TimedTextSpan(id: 0, text: "cafe\u{301}", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit)
        ]
        let cafeSegments = TimedTextComposer.composeSegments(
            displayText: cafeText,
            originalText: cafeText,
            spans: validCafeSpans,
            currentTime: 1.5
        )
        assertRule(cafeSegments.count == 1 && cafeSegments[0].text == cafeText, "Valid combining mark grapheme must succeed")

        // Split combining mark (utf16Length = 4 cuts inside "e\u{301}") -> must fail-closed safely without crash
        let invalidSplitSpans = [
            TimedTextSpan(id: 0, text: "cafe", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 4, granularity: .timedUnit)
        ]
        let splitSegments = TimedTextComposer.composeSegments(
            displayText: cafeText,
            originalText: cafeText,
            spans: invalidSplitSpans,
            currentTime: 1.5
        )
        assertRule(splitSegments.count == 1 && splitSegments[0].text == cafeText, "Split combining mark must safely fail-closed to full text")

        // 5. invalid / out-of-range UTF-16 offsets
        print("[5] Testing out-of-bounds UTF-16 offsets...")
        let oobSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 999, granularity: .timedUnit)
        ]
        let oobSegments = TimedTextComposer.composeSegments(
            displayText: originalInstance1,
            originalText: originalInstance1,
            spans: oobSpans,
            currentTime: 1.5
        )
        assertRule(oobSegments.count == 1 && oobSegments[0].text == originalInstance1, "Out-of-bounds UTF-16 must fail closed safely without crash")

        // 6. Substring text mismatch with span.text
        print("[6] Testing text content mismatch...")
        let mismatchSpans = [
            TimedTextSpan(id: 0, text: "WrongText", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit)
        ]
        let mismatchSegments = TimedTextComposer.composeSegments(
            displayText: originalInstance1,
            originalText: originalInstance1,
            spans: mismatchSpans,
            currentTime: 1.5
        )
        assertRule(mismatchSegments.count == 1 && mismatchSegments[0].text == originalInstance1, "Mismatched span.text must fail closed safely")

        print("PASS: Timed range source contract verified")
    }
}

import Foundation

@main
struct TimedRenderWhitespaceContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() throws {
        print("[1] Testing 'Hello World!' composition with untimed whitespace and punctuation...")
        let originalText1 = "Hello World!"
        let spans1 = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 2.0, endTime: 3.0, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]

        // Check composed string matches originalText at any time
        for t in [0.0, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0] {
            let segments = TimedTextComposer.composeSegments(text: originalText1, spans: spans1, currentTime: t)
            let fullRendered = segments.map(\.text).joined()
            assertRule(fullRendered == originalText1, "Rendered text at t=\(t)s ('\(fullRendered)') must equal originalText ('\(originalText1)')")
        }

        // Check progressive highlight state
        let segs0 = TimedTextComposer.composeSegments(text: originalText1, spans: spans1, currentTime: 0.5)
        assertRule(segs0.allSatisfy { !$0.isHighlighted }, "Before line start, all segments must be unhighlighted")

        let segs1 = TimedTextComposer.composeSegments(text: originalText1, spans: spans1, currentTime: 1.5)
        assertRule(segs1.count == 4, "Expected 4 segments: Hello, space, World, !")
        assertRule(segs1[0].text == "Hello" && segs1[0].isHighlighted == true, "Hello must be highlighted at 1.5s")
        assertRule(segs1[1].text == " " && segs1[1].isHighlighted == false, "Space must be unhighlighted at 1.5s")
        assertRule(segs1[2].text == "World" && segs1[2].isHighlighted == false, "World must be unhighlighted at 1.5s")
        assertRule(segs1[3].text == "!" && segs1[3].isHighlighted == false, "! must be unhighlighted at 1.5s")

        let segs2 = TimedTextComposer.composeSegments(text: originalText1, spans: spans1, currentTime: 2.5)
        assertRule(segs2[0].text == "Hello" && segs2[0].isHighlighted == true, "Hello must be highlighted at 2.5s")
        assertRule(segs2[1].text == " " && segs2[1].isHighlighted == true, "Space before active World must be highlighted at 2.5s")
        assertRule(segs2[2].text == "World" && segs2[2].isHighlighted == true, "World must be highlighted at 2.5s")
        assertRule(segs2[3].text == "!" && segs2[3].isHighlighted == false, "! must be unhighlighted at 2.5s")

        let segs3 = TimedTextComposer.composeSegments(text: originalText1, spans: spans1, currentTime: 3.5)
        assertRule(segs3.allSatisfy { $0.isHighlighted }, "After all spans, entire line including trailing ! must be highlighted")

        print("[2] Testing mixed-language '君と Hello World' with leading and inter-word whitespace...")
        let originalText2 = "君と Hello World"
        let spans2 = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 2.0, endTime: 3.0, utf16Start: 3, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 3.0, endTime: 4.0, utf16Start: 9, utf16Length: 5, granularity: .timedUnit)
        ]

        let segsMixed = TimedTextComposer.composeSegments(text: originalText2, spans: spans2, currentTime: 2.5)
        let fullMixed = segsMixed.map(\.text).joined()
        assertRule(fullMixed == originalText2, "Mixed text composition ('\(fullMixed)') must equal originalText ('\(originalText2)')")
        assertRule(segsMixed[0].text == "君と ", "Leading untimed Japanese text and space must be preserved")
        assertRule(segsMixed[1].text == "Hello" && segsMixed[1].isHighlighted == true, "Hello must be highlighted at 2.5s")
        assertRule(segsMixed[2].text == " ", "Inter-word space must be preserved")
        assertRule(segsMixed[3].text == "World" && segsMixed[3].isHighlighted == false, "World must be unhighlighted at 2.5s")

        print("[3] Testing empty and fallback lines...")
        let emptySegs = TimedTextComposer.composeSegments(text: "", spans: [], currentTime: 1.0)
        assertRule(emptySegs.isEmpty, "Empty string produces empty segments")

        let noSpansSegs = TimedTextComposer.composeSegments(text: "No spans line", spans: [], currentTime: 1.0)
        assertRule(noSpansSegs.count == 1 && noSpansSegs[0].text == "No spans line", "Fallback with no spans returns whole line")

        print("PASS: Timed render whitespace & punctuation contract verified")
    }
}

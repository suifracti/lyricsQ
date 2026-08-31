import Foundation

@main
struct LyricsLayerEnricherTimingContract {
    static func main() {
        print("=== LYRICS LAYER ENRICHER TIMING PRESERVATION CONTRACT ===")

        let spans: [TimedTextSpan] = [
            TimedTextSpan(
                id: 0,
                text: "遥",
                trailingWhitespace: "",
                startTime: 0.917,
                endTime: 1.169,
                utf16Start: 0,
                utf16Length: 1,
                granularity: .timedUnit
            ),
            TimedTextSpan(
                id: 1,
                text: "か",
                trailingWhitespace: "",
                startTime: 1.169,
                endTime: 1.385,
                utf16Start: 1,
                utf16Length: 1,
                granularity: .timedUnit
            ),
            TimedTextSpan(
                id: 2,
                text: "遠",
                trailingWhitespace: "",
                startTime: 1.385,
                endTime: 1.743,
                utf16Start: 2,
                utf16Length: 1,
                granularity: .timedUnit
            )
        ]

        let inputLine = LyricLine(
            timestamp: 0.672,
            originalText: "遥か遠くに浮かぶ星を",
            endTime: 5.109,
            translationText: "在遥远之处浮现的群星",
            romajiText: nil,
            kanaText: nil,
            rubyTokens: nil,
            performerID: "v1",
            timedSpans: spans,
            readingRepresentationID: "readingRepresentation.test",
            readingSurfaceText: "遥か遠くに浮かぶ星を"
        )

        let outputLines = LyricsLayerEnricher.enrich(lines: [inputLine])
        assert(outputLines.count == 1, "Enriched lines must have exactly 1 line")

        let outputLine = outputLines[0]

        // 1. Original text unchanged
        assert(outputLine.originalText == inputLine.originalText, "originalText must remain unchanged")

        // 2. Timed spans preserved exactly
        assert(outputLine.timedSpans != nil, "timedSpans must not be dropped by enricher")
        assert(outputLine.timedSpans?.count == spans.count, "timedSpans count must match")
        for (i, span) in (outputLine.timedSpans ?? []).enumerated() {
            let expected = spans[i]
            assert(span.id == expected.id, "Span id mismatch at index \(i)")
            assert(span.text == expected.text, "Span text mismatch at index \(i)")
            assert(span.startTime == expected.startTime, "Span startTime mismatch at index \(i)")
            assert(span.endTime == expected.endTime, "Span endTime mismatch at index \(i)")
            assert(span.utf16Start == expected.utf16Start, "Span utf16Start mismatch at index \(i)")
            assert(span.utf16Length == expected.utf16Length, "Span utf16Length mismatch at index \(i)")
            assert(span.granularity == expected.granularity, "Span granularity mismatch at index \(i)")
        }

        // 3. Performer and projection metadata preserved
        assert(outputLine.performerID == "v1", "performerID must be preserved")
        assert(outputLine.readingRepresentationID == "readingRepresentation.test", "readingRepresentationID must be preserved")
        assert(outputLine.readingSurfaceText == "遥か遠くに浮かぶ星を", "readingSurfaceText must be preserved")

        // 4. Auxiliary layers (translation, readings) not broken
        assert(outputLine.translationText == "在遥远之处浮现的群星", "translationText must be preserved")
        assert(outputLine.timestamp == 0.672, "timestamp must be preserved")
        assert(outputLine.endTime == 5.109, "endTime must be preserved")

        print("PASS: LyricsLayerEnricher timing preservation contract verified")
    }
}

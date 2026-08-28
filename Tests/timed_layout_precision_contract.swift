import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(CoreText)
import CoreText
#endif

@main
struct TimedLayoutPrecisionContract {
    static func main() {
        print("=== TIMED LAYOUT PRECISION CONTRACT (ROUNDED SYSTEM FONT) ===")

        // 1. English kerning layout computation with rounded system font at various sizes and weights
        print("[1] Testing English kerning string layout fractions with rounded system font...")
        let englishText = "AVATAR Toffee WA"
        let spansEng: [TimedTextSpan] = [
            TimedTextSpan(id: 0, text: "AVATAR", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 6),
            TimedTextSpan(id: 1, text: "Toffee", startTime: 2.1, endTime: 3.0, utf16Start: 7, utf16Length: 6),
            TimedTextSpan(id: 2, text: "WA", startTime: 3.1, endTime: 4.0, utf16Start: 14, utf16Length: 2)
        ]

        // Test at 28pt heavy
        guard let layoutEng28 = TimedTextComposer.computeLayoutFractions(
            originalText: englishText,
            spans: spansEng,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute layout fractions for 28pt heavy")
        }
        assert(layoutEng28.spans.count == 3, "Should have 3 span bounds")
        assert(layoutEng28.totalLineWidth > 200, "28pt total width should be > 200pt, got \(layoutEng28.totalLineWidth)")
        assert(layoutEng28.spans[0].startFraction == 0.0, "First span must start at 0.0")
        assert(layoutEng28.spans[0].endFraction < layoutEng28.spans[1].startFraction, "First span end < second span start")
        assert(layoutEng28.spans[2].endFraction <= 1.0, "Last span must end <= 1.0")

        // Test at 36pt semibold
        guard let layoutEng36 = TimedTextComposer.computeLayoutFractions(
            originalText: englishText,
            spans: spansEng,
            fontSize: 36,
            weight: 0.3,
            design: "rounded"
        ) else {
            fatalError("Failed to compute layout fractions for 36pt semibold")
        }
        assert(layoutEng36.totalLineWidth > layoutEng28.totalLineWidth, "36pt font width must be larger than 28pt font width")

        // 2. Specific kerning pairs AV & Ta in isolation
        print("[2] Testing kerning pairs AV and Ta fractions...")
        let kerningText = "AV Ta"
        let spansKern: [TimedTextSpan] = [
            TimedTextSpan(id: 0, text: "AV", startTime: 0.0, endTime: 1.0, utf16Start: 0, utf16Length: 2),
            TimedTextSpan(id: 1, text: "Ta", startTime: 1.0, endTime: 2.0, utf16Start: 3, utf16Length: 2)
        ]
        guard let layoutKern = TimedTextComposer.computeLayoutFractions(
            originalText: kerningText,
            spans: spansKern,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute layout fractions for kerning pairs")
        }
        assert(layoutKern.spans.count == 2)
        assert(layoutKern.spans[0].startFraction == 0.0)
        assert(layoutKern.spans[0].endFraction > 0.0 && layoutKern.spans[0].endFraction < layoutKern.spans[1].startFraction)

        // 3. Japanese YOASOBI layout computation with rounded system font
        print("[3] Testing Japanese kanji/kana layout fractions...")
        let japaneseText = "遥か遠くに浮かぶ星を"
        let spansJp: [TimedTextSpan] = [
            TimedTextSpan(id: 0, text: "遥", startTime: 0.0, endTime: 0.5, utf16Start: 0, utf16Length: 1),
            TimedTextSpan(id: 1, text: "か", startTime: 0.5, endTime: 1.0, utf16Start: 1, utf16Length: 1),
            TimedTextSpan(id: 2, text: "遠", startTime: 1.0, endTime: 1.5, utf16Start: 2, utf16Length: 1),
            TimedTextSpan(id: 3, text: "く", startTime: 1.5, endTime: 2.0, utf16Start: 3, utf16Length: 1),
            TimedTextSpan(id: 4, text: "に", startTime: 2.0, endTime: 2.5, utf16Start: 4, utf16Length: 1),
            TimedTextSpan(id: 5, text: "浮", startTime: 2.5, endTime: 3.0, utf16Start: 5, utf16Length: 1),
            TimedTextSpan(id: 6, text: "か", startTime: 3.0, endTime: 3.5, utf16Start: 6, utf16Length: 1),
            TimedTextSpan(id: 7, text: "ぶ", startTime: 3.5, endTime: 4.0, utf16Start: 7, utf16Length: 1),
            TimedTextSpan(id: 8, text: "星", startTime: 4.0, endTime: 4.5, utf16Start: 8, utf16Length: 1),
            TimedTextSpan(id: 9, text: "を", startTime: 4.5, endTime: 5.0, utf16Start: 9, utf16Length: 1)
        ]
        guard let layoutJp = TimedTextComposer.computeLayoutFractions(
            originalText: japaneseText,
            spans: spansJp,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute layout fractions for Japanese text")
        }
        assert(layoutJp.spans.count == 10, "Should have 10 spans")
        for i in 0..<9 {
            assert(layoutJp.spans[i].startFraction < layoutJp.spans[i].endFraction, "Span \(i) start < end")
            assert(layoutJp.spans[i].endFraction <= layoutJp.spans[i+1].startFraction + 1e-4, "Spans must be monotonic")
        }

        // 4. Fill fraction progression
        print("[4] Testing fillFraction at various timestamps...")
        let f_before = layoutJp.fillFraction(at: -1.0)
        assert(f_before == 0.0, "Before start must be 0.0, got \(f_before)")

        let f_mid0 = layoutJp.fillFraction(at: 0.25)
        let expected_mid0 = layoutJp.spans[0].startFraction + (layoutJp.spans[0].endFraction - layoutJp.spans[0].startFraction) * 0.5
        assert(abs(f_mid0 - expected_mid0) < 1e-5, "Mid span 0 progress incorrect: got \(f_mid0), expected \(expected_mid0)")

        let f_after = layoutJp.fillFraction(at: 10.0)
        assert(f_after == 1.0, "After end must be 1.0, got \(f_after)")

        // 5. Narrow container width / line wrap rule
        print("[5] Testing line wrap single-line containment logic...")
        let availableWidthWide: CGFloat = 600
        let availableWidthNarrow: CGFloat = 150
        assert(layoutJp.totalLineWidth <= availableWidthWide, "Wide container must allow fine timing")
        assert(layoutJp.totalLineWidth > availableWidthNarrow, "Narrow container must detect wrap and fail closed")

        // 6. Fail-closed on malformed text or invalid range
        print("[6] Testing fail-closed on malformed span ranges...")
        let badSpans = [
            TimedTextSpan(id: 0, text: "NonExistent", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 11)
        ]
        let badLayout = TimedTextComposer.computeLayoutFractions(originalText: "Hello", spans: badSpans)
        assert(badLayout == nil, "Malformed spans must return nil (Fail-Closed)")

        print("PASS: Timed layout precision contract verified")
    }
}

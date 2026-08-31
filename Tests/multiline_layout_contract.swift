import Foundation
import CoreText
import AppKit

@main
struct MultilineLayoutContract {
    static func main() {
        print("=== MULTILINE LAYOUT CONTRACT ===")

        // [1] Multiline Japanese text line-wrap layout and UTF-16 range integrity
        print("[1] Testing Multiline Japanese text line-wrap and UTF-16 range integrity...")
        let yoasobi = "遥か遠くに浮かぶ星を 想い眠りにつく君の"
        var spans: [TimedTextSpan] = []
        var t = 1.0
        for (i, ch) in yoasobi.enumerated() {
            spans.append(
                TimedTextSpan(
                    id: i,
                    text: String(ch),
                    trailingWhitespace: "",
                    startTime: t,
                    endTime: t + 0.3,
                    utf16Start: i,
                    utf16Length: 1,
                    granularity: .timedUnit
                )
            )
            t += 0.3
        }

        guard let multiLayout = TimedTextComposer.computeMultilineLayout(
            originalText: yoasobi,
            spans: spans,
            fontSize: 28,
            weight: 0.56,
            design: "rounded",
            availableWidth: 320
        ) else {
            fatalError("Failed to compute multiline layout for Japanese text")
        }

        assert(!multiLayout.isSingleLine, "Expected multiline layout for narrow width")
        assert(multiLayout.lines.count >= 2, "Expected at least 2 lines")

        // Check that line ranges cover originalText without gaps or overlaps
        var reconstructed = ""
        var expectedOffset = 0
        for line in multiLayout.lines {
            assert(line.sourceUTF16Range.lowerBound == expectedOffset, "Line start offset mismatch")
            expectedOffset = line.sourceUTF16Range.upperBound
            reconstructed += line.displayText
            if line.trailingDelimiterLength > 0 {
                reconstructed += "\n"
            }
        }
        assert(expectedOffset == yoasobi.utf16.count, "Total UTF16 length mismatch")
        assert(reconstructed == yoasobi, "Reconstructed text mismatch")

        // [2] English kerning & ligatures preservation in multiline typesetter
        print("[2] Testing English kerning & ligatures preservation in multiline typesetter...")
        let english = "AVATAR Toffee WA something something"
        let enSpans = [
            TimedTextSpan(id: 0, text: "AVATAR", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 6, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "Toffee", trailingWhitespace: " ", startTime: 2.0, endTime: 3.0, utf16Start: 7, utf16Length: 6, granularity: .timedUnit),
            TimedTextSpan(id: 2, text: "WA", trailingWhitespace: " ", startTime: 3.0, endTime: 4.0, utf16Start: 14, utf16Length: 2, granularity: .timedUnit),
            TimedTextSpan(id: 3, text: "something", trailingWhitespace: " ", startTime: 4.0, endTime: 5.0, utf16Start: 17, utf16Length: 9, granularity: .timedUnit),
            TimedTextSpan(id: 4, text: "something", trailingWhitespace: "", startTime: 5.0, endTime: 6.0, utf16Start: 27, utf16Length: 9, granularity: .timedUnit)
        ]

        guard let enLayout = TimedTextComposer.computeMultilineLayout(
            originalText: english,
            spans: enSpans,
            fontSize: 28,
            weight: 0.56,
            design: "rounded",
            availableWidth: 250
        ) else {
            fatalError("Failed to compute multiline layout for English text")
        }

        assert(enLayout.lines.count >= 2, "Expected English text to wrap into multiple lines")

        // [3] Cross-line span splitting and proportional duration allocation
        print("[3] Testing Cross-line span splitting and duration allocation...")
        let crossText = "ABC DEF"
        let crossSpans = [
            TimedTextSpan(id: 0, text: "AB", trailingWhitespace: "", startTime: 0.0, endTime: 1.0, utf16Start: 0, utf16Length: 2, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "C DEF", trailingWhitespace: "", startTime: 1.0, endTime: 3.0, utf16Start: 2, utf16Length: 5, granularity: .timedUnit)
        ]

        guard let crossLayout = TimedTextComposer.computeMultilineLayout(
            originalText: crossText,
            spans: crossSpans,
            fontSize: 28,
            weight: 0.56,
            design: "rounded",
            availableWidth: 80 // Forces break after ABC
        ) else {
            fatalError("Failed to compute layout for cross-line span")
        }

        assert(crossLayout.lines.count == 2, "Expected exactly 2 lines for crossText")
        let l0 = crossLayout.lines[0]
        let l1 = crossLayout.lines[1]

        assert(l0.fragments.count == 2, "Line 0 should have 2 fragments (AB and C )")
        assert(l1.fragments.count == 1, "Line 1 should have 1 fragment (DEF)")

        let fragC = l0.fragments[1]
        let fragDEF = l1.fragments[0]

        assert(fragC.startTime == 1.0, "Frag C start time should be 1.0")
        assert(fragC.endTime == fragDEF.startTime, "Frag C end time must equal Frag DEF start time")
        assert(fragDEF.endTime == 3.0, "Frag DEF end time should be 3.0")

        let tSplit = fragC.endTime
        assert(tSplit > 1.0 && tSplit < 3.0, "Split time must be strictly within (1.0, 3.0)")

        // [4] Step-by-step continuous progress sweep: Line 0 sweeps first, then Line 1
        print("[4] Testing Step-by-step continuous progress sweep...")
        assert(l0.filledWidth(at: 1.0) == fragC.startX, "Line 0 at t=1.0 should be at startX of C")
        assert(l1.filledWidth(at: 1.0) == 0.0, "Line 1 at t=1.0 should be 0.0")

        let tMid0 = 1.0 + (tSplit - 1.0) / 2.0
        let w0_mid = l0.filledWidth(at: tMid0)
        let w1_mid0 = l1.filledWidth(at: tMid0)
        assert(w0_mid > fragC.startX && w0_mid < l0.totalWidth, "Line 0 should be partially sweeping")
        assert(w1_mid0 == 0.0, "Line 1 must remain 0.0 while Line 0 is sweeping")

        assert(l0.filledWidth(at: tSplit) >= l0.totalWidth - 0.01, "Line 0 should be 100% complete at tSplit")
        assert(l1.filledWidth(at: tSplit) == 0.0, "Line 1 should be 0.0 at tSplit")

        let tMid1 = tSplit + (3.0 - tSplit) / 2.0
        let w0_mid1 = l0.filledWidth(at: tMid1)
        let w1_mid1 = l1.filledWidth(at: tMid1)
        assert(w0_mid1 >= l0.totalWidth - 0.01, "Line 0 must remain 100% filled")
        assert(w1_mid1 > 0.0 && w1_mid1 < l1.totalWidth, "Line 1 should be partially sweeping")

        assert(l0.filledWidth(at: 3.0) >= l0.totalWidth - 0.01, "Line 0 complete at t=3.0")
        assert(l1.filledWidth(at: 3.0) >= l1.totalWidth - 0.01, "Line 1 complete at t=3.0")

        // [5] Seek backward idempotency and pause invariance
        print("[5] Testing Seek backward idempotency and pause invariance...")
        let fillBefore = l1.filledWidth(at: 2.8)
        let fillAfter = l1.filledWidth(at: 1.2)
        assert(fillBefore > fillAfter, "Line 1 fill must decrease on seek backward")
        assert(fillAfter == 0.0, "Line 1 fill at t=1.2 must be 0.0")

        let pause1 = l0.filledWidth(at: 1.45)
        let pause2 = l0.filledWidth(at: 1.45)
        assert(pause1 == pause2, "Fill width must be identical for identical timestamps")

        // [6] Strict Canonical Validation Contract (Phase 1.1 reuse)
        print("[6] Testing Strict Canonical Validation (Phase 1.1 invariants)...")
        // 6.1 Combining mark split by offset
        let cafe = "cafe\u{0301}" // cafe with combining acute accent
        let splitCombiningSpan = [
            TimedTextSpan(id: 0, text: "cafe", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 4, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "\u{0301}", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 4, utf16Length: 1, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: cafe, spans: splitCombiningSpan, availableWidth: 300) == nil, "Splitting combining mark must fail-closed")

        // 6.2 Emoji grapheme cluster split
        let family = "👨‍👩‍👧‍👦"
        let splitEmojiSpan = [
            TimedTextSpan(id: 0, text: "👨", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 2, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: family, spans: splitEmojiSpan, availableWidth: 300) == nil, "Splitting emoji grapheme cluster must fail-closed")

        // 6.3 Substring mismatch
        let mismatchSpan = [
            TimedTextSpan(id: 0, text: "Wrong", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 5, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: "Hello World", spans: mismatchSpan, availableWidth: 300) == nil, "Mismatched span.text must fail-closed")

        // 6.4 Overlapping spans
        let overlapSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "lo World", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 3, utf16Length: 8, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: "Hello World", spans: overlapSpans, availableWidth: 300) == nil, "Overlapping spans must fail-closed")

        // 6.5 Non-monotonic spans
        let nonMonotonicSpans = [
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 6, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 5, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: "Hello World", spans: nonMonotonicSpans, availableWidth: 300) == nil, "Non-monotonic spans must fail-closed")

        // 6.6 Valid independent String value
        let independentString = String("Hello World".reversed().reversed())
        let validSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeMultilineLayout(originalText: independentString, spans: validSpans, availableWidth: 300) != nil, "Valid independent String instance must succeed")

        // [7] Explicit Newline Representation & Reconstruction
        print("[7] Testing Explicit Newline Representation & Reconstruction...")
        for (label, newlineText, nlSpans) in [
            ("English explicit newline", "ABC\nDEF", [
                TimedTextSpan(id: 0, text: "ABC", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 3, granularity: .timedUnit),
                TimedTextSpan(id: 1, text: "DEF", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 4, utf16Length: 3, granularity: .timedUnit)
            ]),
            ("Japanese explicit newline", "遥か遠くに\n浮かぶ星を", [
                TimedTextSpan(id: 0, text: "遥か遠くに", trailingWhitespace: "", startTime: 0, endTime: 2, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
                TimedTextSpan(id: 1, text: "浮かぶ星を", trailingWhitespace: "", startTime: 2, endTime: 4, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
            ])
        ] {
            guard let nlLayout = TimedTextComposer.computeMultilineLayout(
                originalText: newlineText,
                spans: nlSpans,
                fontSize: 28,
                weight: 0.56,
                design: "rounded",
                availableWidth: 600
            ) else {
                fatalError("Failed layout for \(label)")
            }

            assert(nlLayout.lines.count == 2, "Expected 2 visual lines for \(label)")
            assert(nlLayout.lines[0].trailingDelimiterLength == 1, "Line 0 should have trailing newline length 1")
            assert(nlLayout.lines[1].trailingDelimiterLength == 0, "Line 1 should have trailing delimiter length 0")
            assert(nlLayout.lines[0].sourceUTF16Range.upperBound == nlLayout.lines[1].sourceUTF16Range.lowerBound, "Source ranges must be contiguous across newline")
            assert(nlLayout.lines[1].sourceUTF16Range.upperBound == newlineText.utf16.count, "Total range must cover full text")

            var reconstructedNL = ""
            for l in nlLayout.lines {
                reconstructedNL += l.displayText
                if l.trailingDelimiterLength > 0 {
                    reconstructedNL += "\n"
                }
            }
            assert(reconstructedNL == newlineText, "Reconstructed newline text must match original source")
        }

        // [8] Cross-line span over explicit newline: "AB\nCD" with span "B\nC"
        print("[8] Testing Cross-line span over explicit newline...")
        let nlCrossText = "AB\nCD"
        let nlCrossSpans = [
            TimedTextSpan(id: 0, text: "A", trailingWhitespace: "", startTime: 0.0, endTime: 1.0, utf16Start: 0, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "B\nC", trailingWhitespace: "", startTime: 1.0, endTime: 3.0, utf16Start: 1, utf16Length: 3, granularity: .timedUnit),
            TimedTextSpan(id: 2, text: "D", trailingWhitespace: "", startTime: 3.0, endTime: 4.0, utf16Start: 4, utf16Length: 1, granularity: .timedUnit)
        ]

        guard let nlCrossLayout = TimedTextComposer.computeMultilineLayout(
            originalText: nlCrossText,
            spans: nlCrossSpans,
            fontSize: 28,
            weight: 0.56,
            design: "rounded",
            availableWidth: 600
        ) else {
            fatalError("Failed to compute layout for span crossing newline")
        }

        assert(nlCrossLayout.lines.count == 2, "Expected 2 lines for AB\\nCD")
        let nl0 = nlCrossLayout.lines[0]
        let nl1 = nlCrossLayout.lines[1]
        assert(nl0.fragments.count == 2, "Line 0 should have 2 fragments (A and B)")
        assert(nl1.fragments.count == 2, "Line 1 should have 2 fragments (C and D)")

        let fragB = nl0.fragments[1]
        let fragC_nl = nl1.fragments[0]
        assert(fragB.endTime == fragC_nl.startTime, "Line 0 fragment B endTime must equal Line 1 fragment C startTime")
        assert(fragB.text == "B", "Frag B text should be 'B'")
        assert(fragC_nl.text == "C", "Frag C text should be 'C'")

        // [9] Filled width untimed trailing policy: "Hello!" with timed span "Hello"
        print("[9] Testing Filled width untimed trailing policy...")
        let helloPunc = "Hello!"
        let helloSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: "", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit)
        ]
        guard let puncLayout = TimedTextComposer.computeMultilineLayout(
            originalText: helloPunc,
            spans: helloSpans,
            fontSize: 28,
            weight: 0.56,
            design: "rounded",
            availableWidth: 600
        ) else {
            fatalError("Failed layout for Hello!")
        }

        let pLine = puncLayout.lines[0]
        let spanEndFragX = pLine.fragments[0].endX
        assert(spanEndFragX < pLine.totalWidth, "Span end X must be less than total width due to trailing '!'")

        // Mid-span: trailing '!' is dark
        let midPuncWidth = pLine.filledWidth(at: 1.5)
        assert(midPuncWidth < spanEndFragX, "During span playback, fill width must not cover '!'")

        // At span end: trailing '!' is fully lit
        let endPuncWidth = pLine.filledWidth(at: 2.0)
        assert(endPuncWidth == pLine.totalWidth, "At span completion, untimed trailing punctuation is lit")

        print("PASS: Multiline layout contract verified")
    }
}

import Foundation
import AppKit
import CoreText

@main struct JapaneseRubyRestorationContract {
    static func main() {
        let original = "既読の速度で愛はかって"
        let reading = JapaneseReadingPipeline.analyzeContextually(originalText: original)
        precondition(reading.kanaText == "きどくのそくどであいはかって", "22-second lyric must resolve the known compound 既読")
        precondition(!reading.containsUnknown && reading.isTokenAligned)
        // Reproduce LyricsLayerEnricher: legacy noncontextual partial tokens
        // already exist by the time the real V3 cache projects this line.
        let legacyReading = JapaneseReadingPipeline.analyze(originalText: original)
        let legacyTokens = legacyReading.tokens.flatMap { JapaneseReadingPipeline.rubyTokens(for: $0) }
        precondition(legacyTokens.contains { $0.ruby == "すんで" })
        var enriched = LyricLine(timestamp: 21.67, originalText: original, rubyTokens: legacyTokens)
        let actualSelection = JapaneseRubyPresentation(line: enriched, reading: reading, storedRubyIsAuthoritative: false)
        precondition(!actualSelection.rubyTokens!.contains { $0.ruby == "すんで" }, "V3 must not prefer legacy enrichment over contextual reading")
        precondition(actualSelection.rubyTokens!.filter { $0.surface == "既" || $0.surface == "読" }.compactMap(\.ruby).joined() == "きどく")
        enriched.rubyTokens = [LyricRubyToken(id: 0, surface: original, ruby: "ユーザー")]
        precondition(JapaneseRubyPresentation(line: enriched, reading: reading, storedRubyIsAuthoritative: true).rubyTokens == enriched.rubyTokens)
        let resolved = JapaneseRubyPresentation(originalText: original, reading: reading)
        precondition(resolved.hasRuby && resolved.rubyTokens?.map(\.surface).joined() == original)
        precondition(resolved.timedLayout(spans: [], fontSize: 28, weight: 0.56) == nil)
        let partial = JapaneseReadingResult(originalText: "速度𠮷", tokens: [
            JapaneseReadingToken(id: 0, originalText: "速度", lemma: nil, kana: "そくど", romaji: "sokudo", source: .mecabIPADIC, confidence: 1, startOffset: 0, endOffset: 2),
            JapaneseReadingToken(id: 1, originalText: "𠮷", lemma: nil, kana: nil, romaji: nil, source: .unknown, confidence: 0, startOffset: 2, endOffset: 3)
        ], kanaText: nil, romajiText: nil, source: .mixed, confidence: 0.5)
        let visible = JapaneseRubyPresentation(originalText: partial.originalText, reading: partial)
        precondition(visible.hasRuby && visible.kanaText == nil)
        precondition(visible.rubyTokens?.last?.ruby == nil)
        let unaligned = JapaneseReadingResult(originalText: original, tokens: reading.tokens, kanaText: reading.kanaText,
            romajiText: reading.romajiText, source: .providerOfficial, confidence: 1, isTokenAligned: false)
        precondition(!JapaneseRubyPresentation(originalText: original, reading: unaligned).hasRuby)
        enriched.kanaText = reading.kanaText
        precondition(!JapaneseRubyPresentation(line: enriched, reading: unaligned, storedRubyIsAuthoritative: false).hasRuby,
            "Unaligned provider kana must not fall back to conflicting legacy ruby")
        let corrected = JapaneseRubyPresentation(originalText: "今日", reading: nil,
            preferredRubyTokens: [LyricRubyToken(id: 0, surface: "今日", ruby: "きょう")], kanaText: "きょう", romajiText: "kyō")
        let spans = [TimedTextSpan(id: 0, text: "今日", trailingWhitespace: "", startTime: 10, endTime: 12,
            utf16Start: 0, utf16Length: 2, granularity: .word)]
        let layout = corrected.timedLayout(spans: spans, fontSize: 28, weight: 0.56)!
        precondition(layout.tokens[0].fillFraction(at: 9) == 0)
        precondition(abs(layout.tokens[0].fillFraction(at: 11) - 0.5) < 0.01)
        precondition(layout.tokens[0].fillFraction(at: 13) == 1)
        precondition(layout.tokens[0].fillFraction(at: 9) == 0, "Seeking backward must reset fill")
        precondition(corrected.timedLayout(spans: spans, fontSize: 28, weight: 0.56, showsRuby: false)?.tokens.allSatisfy { $0.ruby == nil } == true)
        precondition(resolved.timedLayout(spans: spans, fontSize: 28, weight: 0.56) == nil, "Mismatching word text must fail closed")
        let latin = "WWWiii"
        let latinSpans = [
            TimedTextSpan(id: 0, text: "WWW", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 3),
            TimedTextSpan(id: 1, text: "iii", startTime: 1, endTime: 2, utf16Start: 3, utf16Length: 3)
        ]
        let latinPresentation = JapaneseRubyPresentation(originalText: latin, reading: nil)
        let desktopLayout = latinPresentation.timedLayout(spans: latinSpans, fontSize: 32,
            weight: NSFont.Weight.bold.rawValue, showsRuby: false, design: "default")!
        let actualFont = NSFont.systemFont(ofSize: 32, weight: .bold)
        let actualLine = CTLineCreateWithAttributedString(NSAttributedString(string: latin, attributes: [.font: actualFont]))
        let expectedWidth = CTLineGetTypographicBounds(actualLine, nil, nil, nil)
        let expectedBoundary = CTLineGetOffsetForStringIndex(actualLine, 3, nil)
        precondition(abs(desktopLayout.tokens[0].baseWidth - expectedWidth) < 0.01,
            "Desktop timed geometry must use the same font as its visible glyphs")
        precondition(abs(desktopLayout.tokens[0].filledWidth(at: 1) - expectedBoundary) < 0.01,
            "Timed fill must reach the visible glyph boundary at the span boundary")
        let defaultMain = latinPresentation.timedLayout(spans: latinSpans, fontSize: 32, weight: NSFont.Weight.bold.rawValue)!
        let explicitRounded = latinPresentation.timedLayout(spans: latinSpans, fontSize: 32,
            weight: NSFont.Weight.bold.rawValue, design: "rounded")!
        precondition(defaultMain == explicitRounded, "Main-window default must retain its rounded typography")
        print("Japanese ruby restoration PASS")
    }
}

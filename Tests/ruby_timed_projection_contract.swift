import Foundation
import CoreText
import AppKit

@main
struct RubyTimedProjectionContract {
    static func main() {
        print("=== RUBY TIMED PROJECTION CONTRACT ===")

        // [1] Ruby base reconstruction with plain gaps
        print("[1] Testing Ruby base reconstruction with plain gaps...")
        let original = "遥か遠くに"
        let rubyTokens = [
            LyricRubyToken(id: 10000, surface: "遥", ruby: "はる"),
            LyricRubyToken(id: 20000, surface: "遠", ruby: "とお")
        ]
        let spans = [
            TimedTextSpan(id: 0, text: "遥", trailingWhitespace: "", startTime: 1.0, endTime: 1.3, utf16Start: 0, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "か", trailingWhitespace: "", startTime: 1.3, endTime: 1.6, utf16Start: 1, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 2, text: "遠", trailingWhitespace: "", startTime: 1.6, endTime: 1.9, utf16Start: 2, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 3, text: "く", trailingWhitespace: "", startTime: 1.9, endTime: 2.2, utf16Start: 3, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 4, text: "に", trailingWhitespace: "", startTime: 2.2, endTime: 2.5, utf16Start: 4, utf16Length: 1, granularity: .timedUnit)
        ]

        guard let layout = TimedTextComposer.computeTimedRubyLayout(
            originalText: original,
            spans: spans,
            rubyTokens: rubyTokens,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute TimedRubyLayout for 遥か遠くに")
        }

        assert(layout.tokens.count == 4, "Expected 4 tokens: 遥, か, 遠, くに")
        assert(layout.tokens[0].surface == "遥" && layout.tokens[0].ruby == "はる", "Token 0 mismatch")
        assert(layout.tokens[1].surface == "か" && layout.tokens[1].ruby == nil, "Token 1 mismatch (plain gap)")
        assert(layout.tokens[2].surface == "遠" && layout.tokens[2].ruby == "とお", "Token 2 mismatch")
        assert(layout.tokens[3].surface == "くに" && layout.tokens[3].ruby == nil, "Token 3 mismatch (plain gap くに)")
        assert(layout.tokens[3].fragments.count == 2, "Token くに must contain 2 timed fragments for く and に")
        assert(layout.reconstructedText == original, "Reconstructed text mismatch")

        // [2] Timing/Ruby boundary independence: 1 Ruby token containing multiple Timed spans
        print("[2] Testing Timing/Ruby boundary independence (1 Ruby token, multiple timed spans)...")
        let textMorphology = "今日へ"
        let rubyMorphology = [
            LyricRubyToken(id: 10000, surface: "今日", ruby: "きょう"),
            LyricRubyToken(id: 20000, surface: "へ", ruby: nil)
        ]
        let spansMorphology = [
            TimedTextSpan(id: 0, text: "今", trailingWhitespace: "", startTime: 1.0, endTime: 1.5, utf16Start: 0, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "日", trailingWhitespace: "", startTime: 1.5, endTime: 2.0, utf16Start: 1, utf16Length: 1, granularity: .timedUnit),
            TimedTextSpan(id: 2, text: "へ", trailingWhitespace: "", startTime: 2.0, endTime: 2.5, utf16Start: 2, utf16Length: 1, granularity: .timedUnit)
        ]

        guard let morphLayout = TimedTextComposer.computeTimedRubyLayout(
            originalText: textMorphology,
            spans: spansMorphology,
            rubyTokens: rubyMorphology,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute layout for 今日へ")
        }

        assert(morphLayout.tokens.count == 2, "Expected 2 tokens for 今日 and へ")
        let tokKyou = morphLayout.tokens[0]
        assert(tokKyou.fragments.count == 2, "Token 今日 must contain 2 timed fragments")
        assert(tokKyou.fragments[0].text == "今" && tokKyou.fragments[0].startTime == 1.0 && tokKyou.fragments[0].endTime == 1.5)
        assert(tokKyou.fragments[1].text == "日" && tokKyou.fragments[1].startTime == 1.5 && tokKyou.fragments[1].endTime == 2.0)

        // Test sweep progression inside token 今日
        assert(tokKyou.fillFraction(at: 1.0) == 0.0, "At 1.0 fill must be 0")
        let fracMidKon = tokKyou.fillFraction(at: 1.25)
        assert(fracMidKon > 0.15 && fracMidKon < 0.35, "Midpoint of 今 fraction: \(fracMidKon)")
        let fracEndKon = tokKyou.fillFraction(at: 1.5)
        assert(fracEndKon > 0.45 && fracEndKon < 0.55, "End of 今 fraction: \(fracEndKon)")
        let fracMidNichi = tokKyou.fillFraction(at: 1.75)
        assert(fracMidNichi > 0.65 && fracMidNichi < 0.85, "Midpoint of 日 fraction: \(fracMidNichi)")
        assert(tokKyou.fillFraction(at: 2.0) == 1.0, "At 2.0 fill must be 1.0")

        let tokHe = morphLayout.tokens[1]
        assert(tokHe.fillFraction(at: 1.8) == 0.0, "Token へ before 2.0 must be 0.0")
        assert(tokHe.fillFraction(at: 2.25) > 0.4 && tokHe.fillFraction(at: 2.25) < 0.6, "Token へ mid fraction")
        assert(tokHe.fillFraction(at: 2.5) == 1.0, "Token へ at 2.5 must be 1.0")

        // [3] Reverse independence: 1 Timed span covering multiple Ruby tokens
        print("[3] Testing Reverse independence (1 timed span covering multiple Ruby tokens)...")
        let revText = "今日へ"
        let revRuby = [
            LyricRubyToken(id: 10000, surface: "今", ruby: "こん"),
            LyricRubyToken(id: 20000, surface: "日", ruby: "にち"),
            LyricRubyToken(id: 30000, surface: "へ", ruby: nil)
        ]
        let revSpans = [
            TimedTextSpan(id: 0, text: "今日", trailingWhitespace: "", startTime: 1.0, endTime: 3.0, utf16Start: 0, utf16Length: 2, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "へ", trailingWhitespace: "", startTime: 3.0, endTime: 4.0, utf16Start: 2, utf16Length: 1, granularity: .timedUnit)
        ]

        guard let revLayout = TimedTextComposer.computeTimedRubyLayout(
            originalText: revText,
            spans: revSpans,
            rubyTokens: revRuby,
            fontSize: 28,
            weight: 0.56,
            design: "rounded"
        ) else {
            fatalError("Failed to compute reverse layout")
        }

        assert(revLayout.tokens.count == 3, "Expected 3 tokens")
        let r0 = revLayout.tokens[0] // 今
        let r1 = revLayout.tokens[1] // 日
        assert(r0.fragments.count == 1 && r1.fragments.count == 1)
        assert(r0.fragments[0].endTime == r1.fragments[0].startTime, "Split time must match exactly")
        let splitT = r0.fragments[0].endTime
        assert(splitT > 1.0 && splitT < 3.0, "Split time must be within (1.0, 3.0)")
        assert(r0.fillFraction(at: splitT) == 1.0, "Token 0 completed at splitT")
        assert(r1.fillFraction(at: splitT) == 0.0, "Token 1 starting at splitT")

        // [4] Fail-closed validation
        print("[4] Testing Fail-closed validation...")
        // 4.1 Empty originalText or spans
        assert(TimedTextComposer.computeTimedRubyLayout(originalText: "", spans: spans, rubyTokens: rubyTokens) == nil)
        assert(TimedTextComposer.computeTimedRubyLayout(originalText: original, spans: [], rubyTokens: rubyTokens) == nil)

        // 4.2 Combining mark split
        let cafe = "cafe\u{0301}"
        let splitCombiningSpan = [
            TimedTextSpan(id: 0, text: "cafe", trailingWhitespace: "", startTime: 0, endTime: 1, utf16Start: 0, utf16Length: 4, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "\u{0301}", trailingWhitespace: "", startTime: 1, endTime: 2, utf16Start: 4, utf16Length: 1, granularity: .timedUnit)
        ]
        assert(TimedTextComposer.computeTimedRubyLayout(originalText: cafe, spans: splitCombiningSpan, rubyTokens: nil) == nil)

        // 4.3 Mismatched ruby token text
        let badRuby = [LyricRubyToken(id: 0, surface: "Wrong", ruby: "wrong")]
        assert(TimedTextComposer.computeTimedRubyLayout(originalText: original, spans: spans, rubyTokens: badRuby) == nil)

        // [5] Seek backward idempotency and pause invariance
        print("[5] Testing Seek backward and pause invariance...")
        let pause1 = tokKyou.fillFraction(at: 1.35)
        let pause2 = tokKyou.fillFraction(at: 1.35)
        assert(pause1 == pause2, "Pause invariance")

        let seekBefore = tokHe.fillFraction(at: 2.4)
        let seekAfter = tokHe.fillFraction(at: 1.2)
        assert(seekBefore > seekAfter && seekAfter == 0.0, "Seek backward must retreat cleanly")

        print("PASS: Ruby timed projection contract verified")
    }
}

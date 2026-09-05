import Foundation
import AppKit
import CoreText
@main struct BalancedLyricBreaksContract {
    static func main() {
        let samples = ["クライマックスの決め台詞のように大それていて好き", "君の言葉はなぜだろう すべて映画で言うところの", "臆病とは病だとしたら 治る気配もない僕の", "I keep all of these beautiful memories close to my heart"]
        for text in samples {
            for width: CGFloat in [420, 600, 680, 740, 860] {
                let output = V3LyricDisplayLineBreaker.breakText(text, fontSize: 42, weight: NSFont.Weight.heavy.rawValue, availableWidth: width)
                let lines = output.components(separatedBy: "\n")
                precondition(lines.dropFirst().allSatisfy { $0.first?.isWhitespace != true }, "avoid leading spaces introduced by wrapping")
                precondition(lines.joined() == text, "display reflow preserves every source character")
                let font = TimedTextComposer.makeSystemFont(size: 42, weight: .heavy, design: .rounded)
                let widths = lines.map { CTLineGetTypographicBounds(CTLineCreateWithAttributedString(NSAttributedString(string: $0, attributes: [.font: font])), nil, nil, nil) }
                precondition(widths.allSatisfy { $0 <= width + 0.5 }, "no second system wrap")
                if widths.count > 1 { precondition(widths.min()! / widths.max()! > 0.45, "avoid isolated short tails") }
                print(Int(width), lines)
                let span = TimedTextSpan(id: 0, text: text, startTime: 1, endTime: 8, utf16Start: 0, utf16Length: text.utf16.count)
                let timed = TimedTextComposer.computeMultilineLayout(originalText: text, spans: [span], fontSize: 42, weight: NSFont.Weight.heavy.rawValue, availableWidth: width, balanced: true)!
                precondition(timed.lines.map(\.text) == lines, "timed and plain use identical breaks")
            }
        }
        let authored = "短い一行\n次の行\r\n最後"
        precondition(V3LyricDisplayLineBreaker.breakText(authored, fontSize: 28, weight: 0, availableWidth: 800).replacingOccurrences(of: "\r\n", with: "\n") == authored.replacingOccurrences(of: "\r\n", with: "\n"))
        for authored in ["first\n", "first\r\n", "first\n\nlast", "first\rlast", "first\u{2028}last"] {
            precondition(V3LyricDisplayLineBreaker.breakText(authored, fontSize: 28, weight: 0, availableWidth: 800) == authored, "authored delimiters preserved")
        }
        print("Balanced lyric breaks PASS")
    }
}

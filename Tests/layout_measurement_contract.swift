import Foundation
import CoreText

func measureFullLine(text: String, font: CTFont) -> Double {
    let attrString = NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
    let line = CTLineCreateWithAttributedString(attrString)
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    return width
}

func measureSegmentSum(segments: [String], font: CTFont) -> Double {
    var totalWidth: Double = 0
    for seg in segments {
        let attrString = NSAttributedString(string: seg, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
        let line = CTLineCreateWithAttributedString(attrString)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        totalWidth += width
    }
    return totalWidth
}

let font = CTFontCreateWithName("HelveticaNeue" as CFString, 28, nil)

let testCases: [(name: String, full: String, segments: [String])] = [
    ("English Standard", "Hello World!", ["Hello", " ", "World", "!"]),
    ("English Kerning Pairs", "AVATAR Toffee WA", ["AVATAR", " ", "Toffee", " ", "WA"]),
    ("English Sliced AV", "AV", ["A", "V"]),
    ("English Sliced Ta", "Ta", ["T", "a"]),
    ("English Sliced Wo", "Wo", ["W", "o"]),
    ("Japanese YOASOBI", "遥か遠くに浮かぶ星を", ["遥", "か", "遠", "く", "に", "浮", "か", "ぶ", "星", "を"]),
    ("Mixed", "君と Hello World", ["君", "と", " ", "Hello", " ", "World"])
]

print("=== LAYOUT MEASUREMENT AUDIT ===")
for tc in testCases {
    let fullWidth = measureFullLine(text: tc.full, font: font)
    let segWidth = measureSegmentSum(segments: tc.segments, font: font)
    let diff = segWidth - fullWidth
    let pct = fullWidth > 0 ? (diff / fullWidth) * 100 : 0
    print("[\(tc.name)] Full: \(String(format: "%.3f", fullWidth)) pt | SegSum: \(String(format: "%.3f", segWidth)) pt | Diff: \(String(format: "%+.3f", diff)) pt (\(String(format: "%+.2f", pct))%)")
}

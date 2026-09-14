import Foundation

public enum ReadingScriptConverter {
    private static let traditionalToSimplified: [Character: Character] = [
        "銀": "银", "長": "长", "樂": "乐", "學": "学", "國": "国", "門": "门",
        "車": "车", "東": "东", "風": "风", "慶": "庆", "開": "开", "過": "过",
        "時": "时", "間": "间", "讀": "读", "見": "见", "聽": "听", "歡": "欢",
        "這": "这", "為": "为", "個": "个", "會": "会", "來": "来", "與": "与"
    ]

    public static func convert(_ text: String, using conversion: ScriptConversionID) -> String {
        switch conversion {
        case .none: return text
        case .traditionalToSimplified:
            let mutable = NSMutableString(string: text) as CFMutableString
            if CFStringTransform(mutable, nil, "Traditional-Simplified" as CFString, false) {
                return mutable as String
            }
            return String(text.map { traditionalToSimplified[$0] ?? $0 })
        case .simplifiedToTraditional:
            let mutable = NSMutableString(string: text) as CFMutableString
            if CFStringTransform(mutable, nil, "Simplified-Traditional" as CFString, false) {
                return mutable as String
            }
            let reverse = Dictionary(uniqueKeysWithValues: traditionalToSimplified.map { ($0.value, $0.key) })
            return String(text.map { reverse[$0] ?? $0 })
        }
    }

    /// Converts timed text spans using contextual script conversion against the full line.
    /// Derives the span text directly from the line-level converted text so that individual tokens
    /// never diverge from the displayed converted line due to isolated/context-free conversion.
    public static func convertSpans(
        _ spans: [TimedTextSpan]?,
        originalText: String? = nil,
        convertedText: String? = nil,
        using conversion: ScriptConversionID
    ) -> [TimedTextSpan]? {
        guard let spans, !spans.isEmpty, conversion != .none else { return spans }
        let baseText = originalText ?? spans.map(\.text).joined()
        guard !baseText.isEmpty else { return spans }

        let targetText = convertedText ?? convert(baseText, using: conversion)
        guard targetText != baseText else { return spans }

        if baseText.count == targetText.count {
            var converted: [TimedTextSpan] = []
            converted.reserveCapacity(spans.count)
            let origUtf16 = baseText.utf16
            let targetUtf16 = targetText.utf16

            for span in spans {
                guard span.utf16Start >= 0,
                      span.utf16Length >= 0,
                      span.utf16Start + span.utf16Length <= origUtf16.count,
                      let origStartU16 = origUtf16.index(origUtf16.startIndex, offsetBy: span.utf16Start, limitedBy: origUtf16.endIndex),
                      let origEndU16 = origUtf16.index(origStartU16, offsetBy: span.utf16Length, limitedBy: origUtf16.endIndex),
                      let origStartIdx = String.Index(origStartU16, within: baseText),
                      let origEndIdx = String.Index(origEndU16, within: baseText) else {
                    let cText = convert(span.text, using: conversion)
                    converted.append(
                        TimedTextSpan(
                            id: span.id,
                            text: cText,
                            trailingWhitespace: span.trailingWhitespace,
                            startTime: span.startTime,
                            endTime: span.endTime,
                            utf16Start: span.utf16Start,
                            utf16Length: cText.utf16.count,
                            granularity: span.granularity
                        )
                    )
                    continue
                }

                let charStart = baseText.distance(from: baseText.startIndex, to: origStartIdx)
                let charCount = baseText.distance(from: origStartIdx, to: origEndIdx)

                let targetStartIdx = targetText.index(targetText.startIndex, offsetBy: charStart)
                let targetEndIdx = targetText.index(targetStartIdx, offsetBy: charCount)

                let cSpanText = String(targetText[targetStartIdx..<targetEndIdx])
                guard let targetStartU16 = targetStartIdx.samePosition(in: targetUtf16),
                      let targetEndU16 = targetEndIdx.samePosition(in: targetUtf16) else {
                    continue
                }
                let targetU16Start = targetUtf16.distance(from: targetUtf16.startIndex, to: targetStartU16)
                let targetU16Length = targetUtf16.distance(from: targetStartU16, to: targetEndU16)

                converted.append(
                    TimedTextSpan(
                        id: span.id,
                        text: cSpanText,
                        trailingWhitespace: span.trailingWhitespace,
                        startTime: span.startTime,
                        endTime: span.endTime,
                        utf16Start: targetU16Start,
                        utf16Length: targetU16Length,
                        granularity: span.granularity
                    )
                )
            }
            return converted
        }

        var converted: [TimedTextSpan] = []
        converted.reserveCapacity(spans.count)
        var offset = 0
        for span in spans {
            let cText = convert(span.text, using: conversion)
            let len = cText.utf16.count
            let previousUpper = converted.last.map { $0.utf16Start + $0.utf16Length } ?? 0
            let gap = span.utf16Start - previousUpper
            if gap > 0 {
                offset += gap
            }
            converted.append(
                TimedTextSpan(
                    id: span.id,
                    text: cText,
                    trailingWhitespace: span.trailingWhitespace,
                    startTime: span.startTime,
                    endTime: span.endTime,
                    utf16Start: offset,
                    utf16Length: len,
                    granularity: span.granularity
                )
            )
            offset += len
        }
        return converted
    }

    /// Converts ruby tokens using contextual script conversion against the full line.
    /// Derives the token surface directly from the line-level converted text so that individual tokens
    /// never diverge from the displayed converted line due to isolated/context-free conversion.
    public static func convertRubyTokens(
        _ tokens: [LyricRubyToken]?,
        originalText: String,
        convertedText: String? = nil,
        using conversion: ScriptConversionID
    ) -> [LyricRubyToken]? {
        guard let tokens, !tokens.isEmpty, conversion != .none else { return tokens }
        guard !originalText.isEmpty else { return tokens }

        let targetText = convertedText ?? convert(originalText, using: conversion)
        guard targetText != originalText else { return tokens }

        if originalText.count == targetText.count {
            var result: [LyricRubyToken] = []
            result.reserveCapacity(tokens.count)
            var curOrigIdx = originalText.startIndex

            for token in tokens {
                let charCount = token.surface.count
                guard let nextOrigIdx = originalText.index(curOrigIdx, offsetBy: charCount, limitedBy: originalText.endIndex) else {
                    let convertedSurface = convert(token.surface, using: conversion)
                    result.append(LyricRubyToken(id: token.id, surface: convertedSurface, ruby: token.ruby))
                    continue
                }
                let charStart = originalText.distance(from: originalText.startIndex, to: curOrigIdx)
                let targetStartIdx = targetText.index(targetText.startIndex, offsetBy: charStart)
                let targetEndIdx = targetText.index(targetStartIdx, offsetBy: charCount)
                let cSurface = String(targetText[targetStartIdx..<targetEndIdx])
                result.append(LyricRubyToken(id: token.id, surface: cSurface, ruby: token.ruby))
                curOrigIdx = nextOrigIdx
            }
            return result
        }

        return tokens.map { token in
            LyricRubyToken(id: token.id, surface: convert(token.surface, using: conversion), ruby: token.ruby)
        }
    }
}

// Shared/Models/Models.swift
import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(CoreText)
import CoreText
#endif

public struct TrackArtistLink: Identifiable, Equatable, Hashable, Sendable {
    public let name: String
    public let url: URL?

    public var id: String { url?.absoluteString ?? "name:\(name)" }

    public init(name: String, url: URL? = nil) {
        self.name = name
        self.url = url
    }
}

public struct Track: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval
    public let artworkName: String
    public let isrc: String?
    public let spotifyId: String?
    public let artworkURL: URL?
    public let spotifyURL: URL?
    /// Structured identities are present for catalog results only. Desktop
    /// playback metadata may legitimately leave these empty.
    public let artistLinks: [TrackArtistLink]
    public let albumURL: URL?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        artworkName: String = "music.note",
        isrc: String? = nil,
        spotifyId: String? = nil,
        artworkURL: URL? = nil,
        spotifyURL: URL? = nil,
        artistLinks: [TrackArtistLink] = [],
        albumURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkName = artworkName
        self.isrc = isrc
        self.spotifyId = spotifyId
        self.artworkURL = artworkURL
        self.spotifyURL = spotifyURL
        self.artistLinks = artistLinks
        self.albumURL = albumURL
    }
}

/// A reading/base pair for SwiftUI ruby rendering.
///
/// `surface` is always copied from the original lyric. `ruby` is optional and
/// is only populated when the reading pipeline has a confirmed reading for a
/// token containing Han characters. This keeps unknown readings fail-closed
/// while allowing long readings to overhang their base text naturally.
public struct LyricRubyToken: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let surface: String
    public let ruby: String?
    /// The confirmed kana text that replaces `surface` in the kana-primary
    /// presentation. This is separate from `ruby`: for a token such as
    /// `々`, there may be replacement kana without an annotation to show.
    public let kanaSurface: String?
    public let romaji: String?
    public let confidence: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case surface
        case ruby
        case kanaSurface
        case romaji
        case confidence
    }

    public init(
        id: Int,
        surface: String,
        ruby: String?,
        kanaSurface: String? = nil,
        romaji: String? = nil,
        confidence: Double = 0
    ) {
        self.id = id
        self.surface = surface
        self.ruby = ruby
        self.kanaSurface = kanaSurface
        self.romaji = romaji
        self.confidence = confidence
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        surface = try values.decode(String.self, forKey: .surface)
        ruby = try values.decodeIfPresent(String.self, forKey: .ruby)
        // Older saved token payloads do not have this key.
        kanaSurface = try values.decodeIfPresent(String.self, forKey: .kanaSurface)
        romaji = try values.decodeIfPresent(String.self, forKey: .romaji)
        confidence = try values.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(surface, forKey: .surface)
        try values.encodeIfPresent(ruby, forKey: .ruby)
        try values.encodeIfPresent(kanaSurface, forKey: .kanaSurface)
        try values.encodeIfPresent(romaji, forKey: .romaji)
        try values.encode(confidence, forKey: .confidence)
    }

    public var isWhitespace: Bool {
        !surface.isEmpty && surface.unicodeScalars.allSatisfy {
            CharacterSet.whitespacesAndNewlines.contains($0)
        }
    }

    public var hasRuby: Bool {
        guard let ruby, !ruby.isEmpty, !isWhitespace else { return false }
        return true
    }

    /// Kana-primary text for the third display mode. It never falls back to
    /// a guessed reading; callers only receive a ruby value when the reading
    /// pipeline confirmed one.
    public var kanaReplacementText: String {
        if let kanaSurface, !kanaSurface.isEmpty {
            return kanaSurface
        }
        if hasRuby, let ruby, !ruby.isEmpty {
            return ruby
        }
        return surface
    }
}

public enum LyricTimingGranularity: String, Codable, Sendable, Equatable {
    case syllable
    case word
    case timedUnit
}

public struct TimedTextSpan: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let text: String
    public let trailingWhitespace: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let utf16Start: Int
    public let utf16Length: Int
    public let granularity: LyricTimingGranularity

    public init(
        id: Int,
        text: String,
        trailingWhitespace: String = "",
        startTime: TimeInterval,
        endTime: TimeInterval,
        utf16Start: Int,
        utf16Length: Int,
        granularity: LyricTimingGranularity = .timedUnit
    ) {
        self.id = id
        self.text = text
        self.trailingWhitespace = trailingWhitespace
        self.startTime = startTime
        self.endTime = endTime
        self.utf16Start = utf16Start
        self.utf16Length = utf16Length
        self.granularity = granularity
    }

    public var duration: TimeInterval { max(0, endTime - startTime) }
}

public struct ResolvedGraphemeSpan: Identifiable, Equatable, Sendable {
    public let id: Int
    public let text: String
    public let trailingWhitespace: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let range: Range<String.Index>
    public let granularity: LyricTimingGranularity

    public init(
        id: Int,
        text: String,
        trailingWhitespace: String = "",
        startTime: TimeInterval,
        endTime: TimeInterval,
        range: Range<String.Index>,
        granularity: LyricTimingGranularity
    ) {
        self.id = id
        self.text = text
        self.trailingWhitespace = trailingWhitespace
        self.startTime = startTime
        self.endTime = endTime
        self.range = range
        self.granularity = granularity
    }

    public var duration: TimeInterval { max(0, endTime - startTime) }
}

public struct TimedTextSegment: Equatable, Sendable {
    public let text: String
    /// Progress of this segment: 0.0 (future/unplayed) ... 1.0 (played).
    public let progress: Double
    /// Whether this segment represents an untimed gap (whitespace or punctuation).
    public let isUntimedGap: Bool

    public init(text: String, progress: Double, isUntimedGap: Bool = false) {
        self.text = text
        self.progress = min(max(0.0, progress), 1.0)
        self.isUntimedGap = isUntimedGap
    }

    public init(text: String, isHighlighted: Bool) {
        self.text = text
        self.progress = isHighlighted ? 1.0 : 0.0
        self.isUntimedGap = false
    }

    public var isPlayed: Bool { progress >= 1.0 }
    public var isActive: Bool { progress > 0.0 && progress < 1.0 }
    public var isHighlighted: Bool { progress > 0.0 }
}

public enum TimedTextComposer {
    private struct ResolvedSpan {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
        let range: Range<String.Index>
    }

    /// Resolves `timedSpans` into exact `Range<String.Index>` values on the specific `currentText` instance.
    /// Returns nil if ANY span fails UTF-16 bounds, grapheme boundary conversion, text equality, or monotonicity (Fail-Closed).
    private static func resolveSpans(
        in currentText: String,
        timedSpans: [TimedTextSpan]
    ) -> [ResolvedSpan]? {
        guard !timedSpans.isEmpty else { return nil }
        var resolved: [ResolvedSpan] = []
        resolved.reserveCapacity(timedSpans.count)

        let utf16 = currentText.utf16
        var lastEnd = currentText.startIndex

        for span in timedSpans {
            guard span.utf16Start >= 0,
                  span.utf16Length >= 0,
                  span.utf16Start + span.utf16Length <= utf16.count else {
                return nil
            }
            guard let startU16 = utf16.index(utf16.startIndex, offsetBy: span.utf16Start, limitedBy: utf16.endIndex),
                  let endU16 = utf16.index(startU16, offsetBy: span.utf16Length, limitedBy: utf16.endIndex),
                  let startIdx = String.Index(startU16, within: currentText),
                  let endIdx = String.Index(endU16, within: currentText),
                  startIdx <= endIdx else {
                // Not a valid grapheme cluster boundary in currentText
                return nil
            }
            // Strict monotonicity: spans must not overlap and must proceed forward
            guard startIdx >= lastEnd else {
                return nil
            }
            let extracted = String(currentText[startIdx..<endIdx])
            guard extracted == span.text else {
                return nil
            }
            resolved.append(
                ResolvedSpan(
                    text: span.text,
                    startTime: span.startTime,
                    endTime: span.endTime,
                    range: startIdx..<endIdx
                )
            )
            lastEnd = endIdx
        }
        return resolved
    }

    /// Pure, deterministic progress calculation for a timed span.
    /// Clamped strictly to `0.0...1.0`.
    public static func calculateSpanProgress(
        startTime: TimeInterval,
        endTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double {
        let duration = endTime - startTime
        if duration <= 0 {
            return currentTime >= startTime ? 1.0 : 0.0
        }
        if currentTime <= startTime {
            return 0.0
        }
        if currentTime >= endTime {
            return 1.0
        }
        let raw = (currentTime - startTime) / duration
        return min(max(0.0, raw), 1.0)
    }

    /// Composes display segments while ensuring source-of-truth timing safety.
    /// Resolves `spans` dynamically against `originalText`.
    /// If `displayText != originalText` (e.g. line breaker inserted `\n` or reading surface projection),
    /// or if any span fails grapheme boundary validation, safely falls back to a non-fine-timing full display text segment.
    public static func composeSegments(
        displayText: String,
        originalText: String,
        spans: [TimedTextSpan],
        currentTime: TimeInterval
    ) -> [TimedTextSegment] {
        guard !displayText.isEmpty else { return [] }
        guard !spans.isEmpty else {
            return [TimedTextSegment(text: displayText, progress: 1.0)]
        }
        // Strict identity: displayText must equal originalText
        guard displayText == originalText else {
            return [TimedTextSegment(text: displayText, progress: 1.0)]
        }
        // Resolve spans on this specific originalText instance
        guard let resolvedSpans = resolveSpans(in: originalText, timedSpans: spans) else {
            return [TimedTextSegment(text: displayText, progress: 1.0)]
        }

        var segments: [TimedTextSegment] = []
        var cursor = originalText.startIndex

        for span in resolvedSpans {
            if cursor < span.range.lowerBound {
                let untimedText = String(originalText[cursor..<span.range.lowerBound])
                if !untimedText.isEmpty {
                    let progress = currentTime >= span.startTime ? 1.0 : 0.0
                    segments.append(TimedTextSegment(text: untimedText, progress: progress, isUntimedGap: true))
                }
            }

            let spanText = String(originalText[span.range])
            if !spanText.isEmpty {
                let progress = calculateSpanProgress(
                    startTime: span.startTime,
                    endTime: span.endTime,
                    currentTime: currentTime
                )
                segments.append(TimedTextSegment(text: spanText, progress: progress, isUntimedGap: false))
            }

            cursor = max(cursor, span.range.upperBound)
        }

        if cursor < originalText.endIndex {
            let trailingText = String(originalText[cursor..<originalText.endIndex])
            if !trailingText.isEmpty {
                let lastSpanEnd = resolvedSpans.last?.endTime ?? 0
                let progress = currentTime >= lastSpanEnd ? 1.0 : 0.0
                segments.append(TimedTextSegment(text: trailingText, progress: progress, isUntimedGap: true))
            }
        }

        return segments
    }

    public static func composeSegments(
        text: String,
        spans: [TimedTextSpan],
        currentTime: TimeInterval
    ) -> [TimedTextSegment] {
        composeSegments(displayText: text, originalText: text, spans: spans, currentTime: currentTime)
    }

    #if canImport(AppKit) && canImport(CoreText)
    /// Constructs a CTFont matching SwiftUI's `.system(size:weight:design:)`.
    public static func makeSystemFont(
        size: CGFloat,
        weight: NSFont.Weight = .bold,
        design: NSFontDescriptor.SystemDesign = .rounded
    ) -> CTFont {
        let baseFont = NSFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = baseFont.fontDescriptor.withDesign(design),
           let roundedFont = NSFont(descriptor: descriptor, size: size) {
            return roundedFont as CTFont
        }
        return baseFont as CTFont
    }
    #endif

    /// Computes typographic horizontal layout boundaries for each span across the full, unsplit originalText line using true system font metrics.
    /// Returns nil if spans fail validation or if CoreText typography cannot be computed (Fail-Closed).
    public static func computeLayoutFractions(
        originalText: String,
        spans: [TimedTextSpan],
        fontSize: CGFloat = 28,
        weight: CGFloat = 0.56, // Default to .heavy (0.56) / .bold (0.4)
        design: String = "rounded"
    ) -> TimedLineLayout? {
        guard !originalText.isEmpty, !spans.isEmpty else { return nil }
        guard let resolvedSpans = resolveSpans(in: originalText, timedSpans: spans) else {
            return nil
        }
        #if canImport(AppKit) && canImport(CoreText)
        let nsWeight = NSFont.Weight(weight)
        let sysDesign: NSFontDescriptor.SystemDesign = design == "rounded" ? .rounded : .default
        let font = makeSystemFont(size: fontSize, weight: nsWeight, design: sysDesign)

        let attrString = NSAttributedString(
            string: originalText,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
        let line = CTLineCreateWithAttributedString(attrString)
        let totalWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
        guard totalWidth > 0 else { return nil }

        var spanBounds: [TimedLineLayout.SpanBounds] = []
        spanBounds.reserveCapacity(resolvedSpans.count)

        for span in resolvedSpans {
            let startU16 = span.range.lowerBound.utf16Offset(in: originalText)
            let endU16 = span.range.upperBound.utf16Offset(in: originalText)
            let startX = CTLineGetOffsetForStringIndex(line, startU16, nil)
            let endX = CTLineGetOffsetForStringIndex(line, endU16, nil)
            let startFrac = min(max(0.0, startX / totalWidth), 1.0)
            let endFrac = min(max(0.0, endX / totalWidth), 1.0)
            spanBounds.append(
                TimedLineLayout.SpanBounds(
                    startTime: span.startTime,
                    endTime: span.endTime,
                    startFraction: startFrac,
                    endFraction: endFrac
                )
            )
        }

        return TimedLineLayout(spans: spanBounds, totalLineWidth: CGFloat(totalWidth))
        #else
        return nil
        #endif
    }
}

public struct TimedLineLayout: Equatable, Sendable {
    public struct SpanBounds: Equatable, Sendable {
        public let startTime: TimeInterval
        public let endTime: TimeInterval
        public let startFraction: Double
        public let endFraction: Double

        public init(
            startTime: TimeInterval,
            endTime: TimeInterval,
            startFraction: Double,
            endFraction: Double
        ) {
            self.startTime = startTime
            self.endTime = endTime
            self.startFraction = min(max(0.0, startFraction), 1.0)
            self.endFraction = min(max(0.0, endFraction), 1.0)
        }
    }

    public let spans: [SpanBounds]
    public let totalLineWidth: CGFloat

    public init(spans: [SpanBounds], totalLineWidth: CGFloat = 0) {
        self.spans = spans
        self.totalLineWidth = totalLineWidth
    }

    public func fillFraction(at currentTime: TimeInterval) -> Double {
        guard !spans.isEmpty else { return 1.0 }
        guard let first = spans.first, let last = spans.last else { return 1.0 }
        if currentTime <= first.startTime { return 0.0 }
        if currentTime >= last.endTime { return 1.0 }

        for span in spans {
            if currentTime >= span.startTime && currentTime <= span.endTime {
                let duration = span.endTime - span.startTime
                let p = duration > 0 ? (currentTime - span.startTime) / duration : 1.0
                let clampedP = min(max(0.0, p), 1.0)
                return span.startFraction + (span.endFraction - span.startFraction) * clampedP
            } else if currentTime < span.startTime {
                // In untimed gap before this span
                return span.startFraction
            }
        }
        return 1.0
    }
}

public struct LyricsPresentationClock: Equatable, Sendable {
    public let authoritativePosition: TimeInterval
    public let receivedAtMonotonicTime: TimeInterval
    public let isPlaying: Bool
    public let trackID: String
    public let trackDuration: TimeInterval

    public init(
        authoritativePosition: TimeInterval = 0,
        receivedAtMonotonicTime: TimeInterval = 0,
        isPlaying: Bool = false,
        trackID: String = "",
        trackDuration: TimeInterval = 0
    ) {
        self.authoritativePosition = max(0, authoritativePosition)
        self.receivedAtMonotonicTime = receivedAtMonotonicTime
        self.isPlaying = isPlaying
        self.trackID = trackID
        self.trackDuration = max(0, trackDuration)
    }

    /// Pure monotonic extrapolation of playback position.
    /// Invariant 1: If isPlaying is false, returns authoritativePosition (frozen).
    /// Invariant 2: If isPlaying is true, advances linearly by (now - receivedAtMonotonicTime).
    /// Invariant 3: Clamped to [0, trackDuration] when duration is positive.
    public func presentationTime(at monotonicNow: TimeInterval) -> TimeInterval {
        guard isPlaying else { return authoritativePosition }
        let elapsed = max(0, monotonicNow - receivedAtMonotonicTime)
        let estimated = authoritativePosition + elapsed
        if trackDuration > 0 {
            return min(trackDuration, estimated)
        }
        return estimated
    }
}

public struct LyricLine: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var timestamp: TimeInterval
    public var endTime: TimeInterval?
    public var originalText: String
    public var translationText: String?
    public var romajiText: String?
    public var kanaText: String?
    public var rubyTokens: [LyricRubyToken]?
    /// Performer / duet agent ID (e.g. "v1", "v2" from TTML).
    public var performerID: String?
    /// Word / syllable level timing spans. Optional additive enhancement.
    public var timedSpans: [TimedTextSpan]?
    /// Runtime-only reading projection fields. They are never written back
    /// into the source lyric version; the shared ReadingSessionController
    /// uses them to distinguish pinyin/script-converted display from legacy
    /// Japanese columns.
    public var readingRepresentationID: String?
    public var readingSurfaceText: String?
    
    public init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        originalText: String,
        endTime: TimeInterval? = nil,
        translationText: String? = nil,
        romajiText: String? = nil,
        kanaText: String? = nil,
        rubyTokens: [LyricRubyToken]? = nil,
        performerID: String? = nil,
        timedSpans: [TimedTextSpan]? = nil,
        readingRepresentationID: String? = nil,
        readingSurfaceText: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.endTime = endTime
        self.originalText = originalText
        self.translationText = translationText
        self.romajiText = romajiText
        self.kanaText = kanaText
        self.rubyTokens = rubyTokens
        self.performerID = performerID
        self.timedSpans = timedSpans
        self.readingRepresentationID = readingRepresentationID
        self.readingSurfaceText = readingSurfaceText
    }

    public var hasTimedSpans: Bool {
        guard let timedSpans, !timedSpans.isEmpty else { return false }
        return true
    }

    /// Converts UTF-16 indexed `timedSpans` into exact `Range<String.Index>` spans.
    /// Returns nil if ANY span fails exact Extended Grapheme Cluster boundary validation (Fail-Closed, Contract 4).
    public func resolvedGraphemeSpans() -> [ResolvedGraphemeSpan]? {
        guard let timedSpans, !timedSpans.isEmpty else { return nil }
        var resolved: [ResolvedGraphemeSpan] = []
        resolved.reserveCapacity(timedSpans.count)

        let utf16 = originalText.utf16
        for span in timedSpans {
            guard span.utf16Start >= 0,
                  span.utf16Length >= 0,
                  span.utf16Start + span.utf16Length <= utf16.count else {
                return nil
            }
            guard let startU16 = utf16.index(utf16.startIndex, offsetBy: span.utf16Start, limitedBy: utf16.endIndex),
                  let endU16 = utf16.index(startU16, offsetBy: span.utf16Length, limitedBy: utf16.endIndex),
                  let startIdx = String.Index(startU16, within: originalText),
                  let endIdx = String.Index(endU16, within: originalText),
                  startIdx <= endIdx else {
                // Fails exact grapheme boundary check
                return nil
            }
            let extracted = String(originalText[startIdx..<endIdx])
            guard extracted == span.text else {
                // Text mismatch check
                return nil
            }
            resolved.append(
                ResolvedGraphemeSpan(
                    id: span.id,
                    text: span.text,
                    trailingWhitespace: span.trailingWhitespace,
                    startTime: span.startTime,
                    endTime: span.endTime,
                    range: startIdx..<endIdx,
                    granularity: span.granularity
                )
            )
        }
        return resolved
    }
}

public enum LyricsDisplayMode: String, CaseIterable, Identifiable {
    case mainWindow = "主窗口"
    case floatingWindow = "悬浮歌词"
    case capsulePlayer = "顶部胶囊"
    case fullScreen = "全屏歌词"
    
    public var id: String { rawValue }
}

/// Controls how the confirmed kana layer is presented in the main lyrics view.
///
/// `showKana` remains as a source-compatible computed property for older
/// callers. Turning the layer off/on preserves the last selected visible
/// mode, while choosing a mode directly never depends on that Boolean.
public enum KanaDisplayMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case independentLine = "independentLine"
    case inlineRuby = "inlineRuby"
    case kanaReplacement = "kanaReplacement"
    case hidden = "hidden"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .independentLine: return "独立行"
        case .inlineRuby: return "悬浮注音"
        case .kanaReplacement: return "假名替换"
        case .hidden: return "隐藏"
        }
    }

    public var detail: String {
        switch self {
        case .independentLine: return "整行显示假名，适合初学者对照阅读"
        case .inlineRuby: return "假名贴在对应汉字上方，保持正文连续"
        case .kanaReplacement: return "假名替换汉字，原汉字置于上方作为辅助标注"
        case .hidden: return "不显示假名层"
        }
    }
}

public struct DisplayPreferences: Equatable {
    public var showOriginal: Bool = true
    public var showTranslation: Bool = true
    public var showRomaji: Bool = true
    public var showPinyin: Bool = true
    private var storedKanaDisplayMode: KanaDisplayMode
    private var lastVisibleKanaDisplayMode: KanaDisplayMode
    public var fontSize: CGFloat = 18
    public var opacity: Double = 0.85
    public var alwaysOnTop: Bool = true
    public var assistantFontSize: CGFloat = 14
    public var rubyFontSize: CGFloat = 10
    public var hideDistantAuxiliary: Bool = true

    public var kanaDisplayMode: KanaDisplayMode {
        get { storedKanaDisplayMode }
        set {
            storedKanaDisplayMode = newValue
            if newValue != .hidden {
                lastVisibleKanaDisplayMode = newValue
            }
        }
    }

    /// Compatibility bridge for the previous Boolean setting. It is only a
    /// visibility switch; it does not choose between the three presentations.
    public var showKana: Bool {
        get { kanaDisplayMode != .hidden }
        set {
            if newValue {
                if storedKanaDisplayMode == .hidden {
                    storedKanaDisplayMode = lastVisibleKanaDisplayMode
                }
            } else {
                if storedKanaDisplayMode != .hidden {
                    lastVisibleKanaDisplayMode = storedKanaDisplayMode
                }
                storedKanaDisplayMode = .hidden
            }
        }
    }

    public init(
        showOriginal: Bool = true,
        showTranslation: Bool = true,
        showRomaji: Bool = true,
        showPinyin: Bool = true,
        showKana: Bool = false,
        kanaDisplayMode: KanaDisplayMode? = nil,
        fontSize: CGFloat = 18,
        opacity: Double = 0.85,
        alwaysOnTop: Bool = true,
        assistantFontSize: CGFloat = 14,
        rubyFontSize: CGFloat = 10,
        hideDistantAuxiliary: Bool = true
    ) {
        self.showOriginal = showOriginal
        self.showTranslation = showTranslation
        self.showRomaji = showRomaji
        self.showPinyin = showPinyin
        let selectedMode = kanaDisplayMode ?? (showKana ? .independentLine : .hidden)
        self.storedKanaDisplayMode = selectedMode
        self.lastVisibleKanaDisplayMode = selectedMode == .hidden
            ? .independentLine
            : selectedMode
        self.fontSize = fontSize
        self.opacity = opacity
        self.alwaysOnTop = alwaysOnTop
        self.assistantFontSize = assistantFontSize
        self.rubyFontSize = rubyFontSize
        self.hideDistantAuxiliary = hideDistantAuxiliary
    }
}

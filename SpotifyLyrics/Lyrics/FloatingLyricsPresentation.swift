import Foundation

/// Stable identifiers for the two renderers that can be selected for the
/// single retained floating lyrics panel.
public enum FloatingLyricsPresentationVersion: String, CaseIterable, Codable, Sendable {
    case legacyPanel = "floatingLyrics.legacyPanel.v1"
    case transparentV2 = "floatingLyrics.transparent.v2"

    public static let current: Self = .transparentV2
    public static let archived: [Self] = [.legacyPanel]

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .legacyPanel: return "旧版卡片"
        case .transparentV2: return "透明桌面歌词"
        }
    }
}

public enum FloatingLyricsSurfaceStyle: String, CaseIterable, Codable, Sendable {
    case ultraTransparent
    case lightMaterial

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .ultraTransparent: return "超透明"
        case .lightMaterial: return "浅色材质"
        }
    }
}

/// Pure presentation helpers shared by the floating view and its contract
/// tests. This layer contains no playback clock and never mutates lyrics.
public struct FloatingLyricsSelection: Equatable, Sendable {
    public let visibleIndices: [Int]
    public let currentIndex: Int?
    public let autoScroll: Bool

    public init(visibleIndices: [Int], currentIndex: Int?, autoScroll: Bool) {
        self.visibleIndices = visibleIndices
        self.currentIndex = currentIndex
        self.autoScroll = autoScroll
    }
}

public enum FloatingLyricsPresentationHelper {
    public static func selection(
        lines: [LyricLine],
        currentIndex: Int?,
        isSynchronized: Bool,
        isPlaying: Bool,
        precedingCount: Int = 0,
        followingCount: Int = 1
    ) -> FloatingLyricsSelection {
        guard isSynchronized, !lines.isEmpty else {
            return FloatingLyricsSelection(
                visibleIndices: lines.indices.map { $0 },
                currentIndex: nil,
                autoScroll: false
            )
        }

        // Before the first timed line there is no current lyric yet. Keep a
        // small leading projection instead of expanding to the full document;
        // the floating window must remain bounded even during an intro.
        guard let currentIndex, lines.indices.contains(currentIndex) else {
            let upper = min(lines.count - 1, max(0, followingCount))
            return FloatingLyricsSelection(
                visibleIndices: Array(0...upper),
                currentIndex: nil,
                autoScroll: false
            )
        }

        let lower = max(0, currentIndex - max(0, precedingCount))
        let upper = min(lines.count - 1, currentIndex + max(0, followingCount))
        return FloatingLyricsSelection(
            visibleIndices: Array(lower...upper),
            currentIndex: currentIndex,
            // A paused player still needs the current line to remain in view;
            // the helper never advances time and only describes the target.
            autoScroll: true
        )
    }

    /// Kept deliberately small: the floating window never owns a timer. It
    /// is useful for pure contracts and for callers that need to reason about
    /// a paused state without starting a second playback clock.
    public static func advance(
        currentTime: TimeInterval,
        elapsed: TimeInterval,
        isPlaying: Bool
    ) -> TimeInterval {
        guard isPlaying, elapsed.isFinite, elapsed > 0 else { return currentTime }
        return currentTime + elapsed
    }
}

/// Reserve the same control strip before and during hover so lyrics never jump
/// or sit under controls. Short panels devote their scroll area to one verse.
public struct FloatingLyricsLayout: Equatable, Sendable {
    public let toolbarHeight: CGFloat = 36
    public let contentWidth: CGFloat
    public let followingCount: Int

    public init(width: CGFloat, height: CGFloat) {
        contentWidth = max(1, width.isFinite ? width - 32 : 328)
        followingCount = height >= 280 ? 1 : 0
    }
}

public enum FloatingDesktopLineMode: String, CaseIterable, Sendable {
    case single, double
    public var title: String { self == .single ? "单行" : "双行" }
}

public enum FloatingDesktopTheme: String, CaseIterable, Sendable {
    case mint, amber, ice
    public var title: String {
        switch self { case .mint: return "薄荷"; case .amber: return "暖金"; case .ice: return "冰蓝" }
    }
}

public struct FloatingDesktopColor: Equatable, Sendable {
    public let hex: String
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(hex: String, fallback: String) {
        func parse(_ value: String) -> UInt32? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let clean = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
            guard clean.count == 6, clean.allSatisfy({ $0.isHexDigit }) else { return nil }
            return UInt32(clean, radix: 16)
        }
        let value = parse(hex) ?? parse(fallback) ?? 0xFFFFFF
        self.hex = String(format: "%06X", value)
        red = Double((value >> 16) & 255) / 255
        green = Double((value >> 8) & 255) / 255
        blue = Double(value & 255) / 255
    }
}

public enum FloatingDesktopTypography {
    public static func outlineWidth(_ value: Double) -> Double {
        value.isFinite ? min(3, max(0, value)) : 1.25
    }

    public static func panelOpacity(value: Double, transparent: Bool, keepsTextOpaque: Bool) -> Double {
        if transparent && keepsTextOpaque { return 1 }
        return value.isFinite ? min(1, max(0.45, value)) : 0.96
    }

    public static func firstVisible(_ values: [String?]) -> String? {
        values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
    }

    public static func ribbonHeight(fontSize: Double, hasRuby: Bool, outlineWidth: Double) -> Double {
        let inset = 2 * (Self.outlineWidth(outlineWidth) + 1)
        return ceil(fontSize * 1.3) + inset
            + (hasRuby ? ceil(fontSize * 0.45 * 1.3) + inset + 2 : 0)
    }

    public static func fittedFontSize(requested: Double, height: Double, doubleLine: Bool, hasRuby: Bool = false, outlineWidth: Double = 0) -> Double {
        var size = fontSize(requested)
        let available = height.isFinite ? max(1, height) : 84
        while size > 12 {
            let primary = ribbonHeight(fontSize: size, hasRuby: hasRuby, outlineWidth: outlineWidth)
            let companion = doubleLine ? ribbonHeight(fontSize: size * 0.66, hasRuby: false, outlineWidth: outlineWidth) + 7 : 0
            if primary + companion + 16 <= available { break }
            size -= 0.25
        }
        return max(12, size)
    }

    /// Spatial reveal only: never used as word highlighting or a playback clock.
    public static func ribbonOffset(textWidth: Double, viewport: Double, elapsed: Double, duration: Double) -> Double {
        guard textWidth.isFinite, viewport.isFinite, elapsed.isFinite, duration.isFinite else { return 0 }
        let overflow = max(0, textWidth - viewport)
        let progress = min(1, max(0, (elapsed - 0.5) / max(1, duration - 1)))
        return overflow * progress
    }

    public static func fontSize(_ value: Double) -> Double {
        value.isFinite ? min(64, max(22, value)) : 34
    }

    public static func companion(mode: FloatingDesktopLineMode, translation: String?, next: String?) -> String? {
        guard mode == .double else { return nil }
        return [translation, next].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    public static func segments(line: LyricLine, currentTime: TimeInterval) -> [TimedTextSegment]? {
        guard let spans = line.timedSpans, !spans.isEmpty,
              spans.allSatisfy({ $0.startTime.isFinite && $0.endTime.isFinite && $0.endTime > $0.startTime }),
              currentTime.isFinite else { return nil }
        return TimedTextComposer.composeSegments(displayText: line.originalText,
            originalText: line.originalText, spans: spans, currentTime: currentTime)
    }
}

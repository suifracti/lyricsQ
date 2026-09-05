import Foundation

@main
struct FloatingLyricsContract {
    static func main() {
        let lines = (0..<7).map { index in
            LyricLine(timestamp: TimeInterval(index * 10), originalText: "line \(index)")
        }

        let synchronized = FloatingLyricsPresentationHelper.selection(
            lines: lines,
            currentIndex: 3,
            isSynchronized: true,
            isPlaying: true
        )
        precondition(synchronized.currentIndex == 3)
        precondition(Set(synchronized.visibleIndices) == Set(3...4))
        precondition(synchronized.autoScroll)

        let plain = FloatingLyricsPresentationHelper.selection(
            lines: lines,
            currentIndex: 3,
            isSynchronized: false,
            isPlaying: true
        )
        precondition(plain.currentIndex == nil)
        precondition(!plain.autoScroll)

        let beforeFirstLine = FloatingLyricsPresentationHelper.selection(
            lines: lines,
            currentIndex: nil,
            isSynchronized: true,
            isPlaying: true
        )
        precondition(beforeFirstLine.currentIndex == nil)
        precondition(beforeFirstLine.visibleIndices == Array(0...1))
        precondition(!beforeFirstLine.autoScroll)

        let paused = FloatingLyricsPresentationHelper.advance(
            currentTime: 12,
            elapsed: 0.2,
            isPlaying: false
        )
        precondition(paused == 12)

        let active = FloatingLyricsPresentationHelper.selection(
            lines: lines,
            currentIndex: LyricsTimeline.activeLineIndex(
                lines: lines,
                time: 35,
                isSynchronized: true
            ),
            isSynchronized: true,
            isPlaying: true
        )
        precondition(active.currentIndex == LyricsTimeline.activeLineIndex(
            lines: lines,
            time: 35,
            isSynchronized: true
        ))

        precondition(LyricsTimeline.activeLineIndex(lines: lines, time: -1, isSynchronized: true) == nil)
        let repeated = [
            LyricLine(timestamp: 0, originalText: "zero"),
            LyricLine(timestamp: 10, originalText: "first"),
            LyricLine(timestamp: 10, originalText: "second")
        ]
        precondition(LyricsTimeline.activeLineIndex(lines: repeated, time: 10, isSynchronized: true) == 2)
        precondition(LyricsTimeline.activeLineIndex(lines: lines, time: 35, isSynchronized: false) == nil)

        let compact = FloatingLyricsLayout(width: 360, height: 120)
        precondition(compact.toolbarHeight == 36)
        precondition(compact.contentWidth == 328)
        precondition(compact.followingCount == 0)
        precondition(FloatingLyricsLayout(width: 620, height: 320).followingCount == 1)
        precondition(FloatingLyricsLayout(width: 0, height: 0).contentWidth >= 1)
        precondition(FloatingDesktopTypography.fontSize(34) == 34)
        precondition(FloatingDesktopTypography.fontSize(900) == 64)
        precondition(FloatingDesktopTypography.fontSize(.nan) == 34)
        precondition(FloatingDesktopTypography.companion(mode: .single, translation: "译文", next: "next") == nil)
        precondition(FloatingDesktopTypography.companion(mode: .double, translation: "译文", next: "next") == "译文")
        precondition(FloatingDesktopTypography.companion(mode: .double, translation: "  ", next: "next") == "next")
        let untimed = FloatingDesktopTypography.segments(line: lines[0], currentTime: 5)
        precondition(untimed == nil, "Line timestamps must never synthesize word progress")
        var timed = LyricLine(timestamp: 0, originalText: "你好")
        timed.timedSpans = [
            TimedTextSpan(id: 0, text: "你", startTime: 1, endTime: 2, utf16Start: 0, utf16Length: 1),
            TimedTextSpan(id: 1, text: "好", startTime: 2, endTime: 3, utf16Start: 1, utf16Length: 1)
        ]
        let progress = FloatingDesktopTypography.segments(line: timed, currentTime: 1.5)!
        precondition(progress.map(\.text).joined() == "你好")
        precondition(progress.map(\.progress) == [0.5, 0])
        precondition(FloatingDesktopTypography.segments(line: timed, currentTime: .nan) == nil)
        precondition(FloatingDesktopTypography.firstVisible(["  ", "", "かな"]) == "かな")
        precondition(FloatingDesktopTypography.ribbonOffset(textWidth: 800, viewport: 300, elapsed: 0, duration: 8) == 0)
        precondition(FloatingDesktopTypography.ribbonOffset(textWidth: 800, viewport: 300, elapsed: 8, duration: 8) == 500)
        precondition(FloatingDesktopTypography.ribbonOffset(textWidth: 100, viewport: 300, elapsed: 4, duration: 8) == 0)
        let ribbonSize = FloatingDesktopTypography.fittedFontSize(requested: 34, height: 84, doubleLine: true)
        precondition(ribbonSize >= 22 && ribbonSize * 2.15 + 23 <= 84)
        let custom = FloatingDesktopColor(hex: "#12abef", fallback: "FFFFFF")
        precondition(custom.hex == "12ABEF")
        precondition(abs(custom.red - 18.0 / 255) < 0.0001)
        precondition(FloatingDesktopColor(hex: "not-a-color", fallback: "102030").hex == "102030")
        precondition(FloatingDesktopColor(hex: "12#3456", fallback: "102030").hex == "102030")
        precondition(FloatingDesktopColor(hex: "#FFFFFF00", fallback: "102030").hex == "102030", "Text colors must not accept hidden alpha")
        precondition(FloatingDesktopTypography.outlineWidth(.nan) == 1.25)
        precondition(FloatingDesktopTypography.outlineWidth(99) == 3)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: true, keepsTextOpaque: true) == 1)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: false, keepsTextOpaque: true) == 0.5)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: true, keepsTextOpaque: false) == 0.5)
        let rubySize = FloatingDesktopTypography.fittedFontSize(requested: 64, height: 84, doubleLine: true, hasRuby: true, outlineWidth: 1.25)
        let rubyHeight = FloatingDesktopTypography.ribbonHeight(fontSize: rubySize, hasRuby: true, outlineWidth: 1.25)
        let auxiliaryHeight = FloatingDesktopTypography.ribbonHeight(fontSize: rubySize * 0.66, hasRuby: false, outlineWidth: 1.25)
        precondition(rubyHeight + auxiliaryHeight + 23 <= 84.01, "Minimum desktop must contain top ruby and outline as well as both lines")
        print("floating lyrics pure-data contract passed")
    }
}

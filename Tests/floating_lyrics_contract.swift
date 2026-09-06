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
        precondition(FloatingDesktopTypography.selectedCompanion(mode: .double, selection: "next", translation: "译文", next: "下一句", kana: "かな", reading: "kana") == "下一句")
        precondition(FloatingDesktopTypography.selectedCompanion(mode: .double, selection: "kana", translation: "译文", next: "下一句", kana: "かな", reading: "kana") == "かな")
        precondition(FloatingDesktopTypography.selectedCompanion(mode: .double, selection: "translation", translation: "", next: "下一句", kana: "かな", reading: "kana") == nil)
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
        precondition(FloatingDesktopTypography.ribbonPlacementOffset(measuredWidth: nil, viewport: 300, elapsed: 4, duration: 8) == 0)
        precondition(FloatingDesktopTypography.ribbonPlacementOffset(measuredWidth: 0, viewport: 300, elapsed: 4, duration: 8) == 0)
        precondition(FloatingDesktopTypography.ribbonPlacementOffset(measuredWidth: 100, viewport: 300, elapsed: 4, duration: 8) == 100)
        precondition(FloatingDesktopTypography.ribbonAlignment(measuredWidth: nil, viewport: 300) == .center)
        precondition(FloatingDesktopTypography.ribbonAlignment(measuredWidth: 0, viewport: 300) == .center)
        precondition(FloatingDesktopTypography.ribbonAlignment(measuredWidth: 100, viewport: 300) == .center)
        precondition(FloatingDesktopTypography.ribbonAlignment(measuredWidth: 400, viewport: 300) == .leading)
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
        let plainTextPlan = FloatingDesktopTextRenderPlan(outlineWidth: 0, fontSize: 34)
        precondition(!plainTextPlan.outlineEnabled)
        precondition(plainTextPlan.fillPassIsOpaque)
        let outlinedTextPlan = FloatingDesktopTextRenderPlan(outlineWidth: 1.25, fontSize: 34)
        precondition(outlinedTextPlan.outlineEnabled)
        precondition(outlinedTextPlan.strokeWidthPercent > 0)
        precondition(outlinedTextPlan.fillPassIsOpaque)
        let highlightTextPlan = FloatingDesktopTextRenderPlan(outlineWidth: 1.25, fontSize: 34, drawOutline: false)
        precondition(!highlightTextPlan.outlineEnabled)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: true, keepsTextOpaque: true) == 1)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: false, keepsTextOpaque: true) == 0.5)
        precondition(FloatingDesktopTypography.panelOpacity(value: 0.5, transparent: true, keepsTextOpaque: false) == 0.5)
        let rubySize = FloatingDesktopTypography.fittedFontSize(requested: 64, height: 84, doubleLine: true, hasRuby: true, outlineWidth: 1.25)
        let rubyHeight = FloatingDesktopTypography.ribbonHeight(fontSize: rubySize, hasRuby: true, outlineWidth: 1.25)
        let auxiliaryHeight = FloatingDesktopTypography.ribbonHeight(fontSize: rubySize * 0.66, hasRuby: false, outlineWidth: 1.25)
        precondition(rubyHeight + auxiliaryHeight + 23 <= 84.01, "Minimum desktop must contain top ruby and outline as well as both lines")

        let lyricsFrame = CGRect(x: 482, y: 1163, width: 620, height: 220)
        let visibleFrame = CGRect(x: 0, y: 23, width: 1920, height: 1394)
        let sidePanel = FloatingLyricsStylePanelLayout(
            lyricsFrame: lyricsFrame,
            panelSize: CGSize(width: 360, height: 660),
            visibleFrame: visibleFrame
        )
        precondition(sidePanel.placement == .right)
        precondition(sidePanel.frame.minX >= lyricsFrame.maxX + 12)
        precondition(!sidePanel.frame.intersects(lyricsFrame))

        let leftPlacement = FloatingLyricsStylePanelLayout(
            lyricsFrame: CGRect(x: 1260, y: 600, width: 620, height: 220),
            panelSize: CGSize(width: 300, height: 500),
            visibleFrame: visibleFrame
        )
        precondition(leftPlacement.placement == .left)
        precondition(!leftPlacement.frame.intersects(CGRect(x: 1260, y: 600, width: 620, height: 220)))
        print("floating lyrics pure-data contract passed")
    }
}

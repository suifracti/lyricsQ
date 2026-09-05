import SwiftUI

/// The production floating renderer. It observes the existing PlaybackState
/// and WindowController only; it owns no provider, session, translation state
/// or playback timer. All lyric rows come from the shared live session.
struct FloatingLyricsView: View {
    @ObservedObject var state: PlaybackState
    @ObservedObject var windowController: FloatingLyricsWindowController
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var showsStyle = false

    private var presentationVersion: FloatingLyricsPresentationVersion {
        settings.floatingLyricsPresentation
    }

    private var presentationStyle: FloatingLyricsSurfaceStyle {
        settings.floatingLyricsSurfaceStyle
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                surfaceBackground

                VStack(spacing: 0) {
                    toolbar
                        .frame(height: FloatingLyricsLayout(width: geometry.size.width, height: geometry.size.height).toolbarHeight)
                    content(in: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.lyricAgentPresentationMap, LyricAgentPresentationMap(lines: state.liveLyrics))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("悬浮歌词")
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button { state.previousTrack() } label: { Image(systemName: "backward.fill").frame(width: 24, height: 26) }
                .accessibilityLabel("上一首")
            Button { state.togglePlayPause() } label: { Image(systemName: state.isPlaying ? "pause.fill" : "play.fill").frame(width: 24, height: 26) }
                .accessibilityLabel(state.isPlaying ? "暂停" : "播放")
            Button { state.nextTrack() } label: { Image(systemName: "forward.fill").frame(width: 24, height: 26) }
                .accessibilityLabel("下一首")
            Text(windowController.interactionMode == .locked ? "已锁定" : "拖动移动")
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 4)
            Button { showsStyle.toggle() } label: { Image(systemName: "textformat.size").frame(width: 26, height: 26) }
                .accessibilityLabel("桌面歌词样式")
                .popover(isPresented: $showsStyle) { styleControls }

            Button {
                windowController.toggleInteractionMode()
            } label: {
                Image(systemName: windowController.interactionMode == .locked ? "lock.open" : "lock")
                    .frame(width: 26, height: 26)
            }
            .help(windowController.interactionMode == .locked ? "解锁悬浮歌词" : "锁定悬浮歌词")
            .accessibilityLabel(windowController.interactionMode == .locked ? "解锁悬浮歌词" : "锁定悬浮歌词")
            Button {
                windowController.setInteractionMode(.passThrough)
            } label: {
                Image(systemName: "cursorarrow.slash").frame(width: 26, height: 26)
            }
            .help("启用鼠标穿透；可在应用菜单恢复交互")
            .accessibilityLabel("启用鼠标穿透")
            Button { windowController.close() } label: {
                Image(systemName: "xmark").frame(width: 26, height: 26)
            }
            .help("隐藏悬浮歌词")
            .accessibilityLabel("隐藏悬浮歌词")
        }
        .font(.system(size: 11, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 6)
        .opacity((isHovering || showsStyle) && windowController.interactionMode != .passThrough ? 1 : 0)
        .allowsHitTesting((isHovering || showsStyle) && windowController.interactionMode != .passThrough)
        .accessibilityHidden(windowController.interactionMode == .passThrough)
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        switch presentationVersion {
        case .legacyPanel:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
        case .transparentV2:
            switch presentationStyle {
            case .ultraTransparent:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(isHovering ? 0.14 : 0), lineWidth: 1)
                    }
            case .lightMaterial:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial.opacity(0.66))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }

    @ViewBuilder
    private func content(in geometry: GeometryProxy) -> some View {
        let documentState = state.liveLyricsState
        let rows = state.liveLyrics
        let layout = FloatingLyricsLayout(width: geometry.size.width, height: geometry.size.height)
        let width = layout.contentWidth

        switch documentState {
        case .loaded, .alignmentPreview:
            if state.liveLyricsAreSynchronized, !rows.isEmpty {
                if presentationVersion == .transparentV2 {
                    desktopVerse(rows, width: width, height: geometry.size.height - layout.toolbarHeight)
                } else {
                    synchronizedRows(rows, width: width, followingCount: layout.followingCount)
                }
            } else if !rows.isEmpty {
                plainRows(rows, width: width, status: "纯文本 / 未排轴")
            } else {
                statusView(documentState)
            }
        case .alignmentQueued, .alignmentRunning:
            if !rows.isEmpty {
                plainRows(rows, width: width, status: "纯文本 / 未排轴")
            } else {
                statusView(documentState)
            }
        case .mockPreview, .loading, .idle, .noLyrics, .noSelection, .noMatch, .candidates, .failed:
            if !rows.isEmpty, documentState.isShowingRows {
                plainRows(rows, width: width, status: "纯文本")
            } else {
                statusView(documentState)
            }
        }
    }

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("桌面歌词").font(.headline)
            Picker("行数", selection: $settings.floatingDesktopLineMode) {
                ForEach(FloatingDesktopLineMode.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
            }.pickerStyle(.segmented)
            HStack {
                Text("字号")
                Slider(value: $settings.floatingDesktopFontSize, in: 22...64, step: 1)
                Text("\(Int(settings.floatingDesktopFontSize))").monospacedDigit().frame(width: 26)
            }
            Picker("配色", selection: $settings.floatingDesktopTheme) {
                ForEach(FloatingDesktopTheme.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
            }.pickerStyle(.segmented)
            Picker("第二行", selection: $settings.floatingDesktopCompanion) {
                Text("译文 / 下一句").tag("translation")
                Text("下一句").tag("next")
                Text("假名").tag("kana")
                Text("罗马音 / 拼音").tag("reading")
            }
            Text("第二行使用已开启且可用的歌词层，缺失时显示下一句。")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("共享歌词层").font(.caption).foregroundStyle(.secondary)
            Toggle("原文", isOn: $settings.displayPreferences.showOriginal)
            Toggle("译文", isOn: $settings.displayPreferences.showTranslation)
            Toggle("罗马音", isOn: $settings.displayPreferences.showRomaji)
            Toggle("拼音", isOn: $settings.displayPreferences.showPinyin)
            Toggle("假名", isOn: $settings.displayPreferences.showKana)
            Text("桌面读音在第二行显示；主窗口的注音格式保持原设置。")
                .font(.caption).foregroundStyle(.secondary)
            Text("逐字变色仅用于带真实逐字时间的歌词；单行时间不模拟逐字进度。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(18).frame(width: 300)
    }

    private var desktopAccent: Color {
        switch FloatingDesktopTheme(rawValue: settings.floatingDesktopTheme) ?? .mint {
        case .mint: return Color(red: 0.40, green: 1, blue: 0.77)
        case .amber: return Color(red: 1, green: 0.82, blue: 0.30)
        case .ice: return Color(red: 0.45, green: 0.83, blue: 1)
        }
    }

    private func desktopVerse(_ rows: [LyricLine], width: CGFloat, height: CGFloat) -> some View {
        let index = state.liveCurrentLineIndex.flatMap { rows.indices.contains($0) ? $0 : nil } ?? 0
        let line = rows[index]
        let preferences = state.preferences
        let japanese = LyricsLanguageGate.allowsJapaneseReadings(language: state.liveLyricsLanguage, text: line.originalText)
        let kana = japanese && preferences.showKana ? line.kanaText.map(JapaneseRomanizer.displayKana) : nil
        let isPinyin = line.readingRepresentationID?.hasPrefix("readingRepresentation.pinyin") == true
        let reading = (isPinyin ? preferences.showPinyin : japanese && preferences.showRomaji) ? line.romajiText : nil
        let original = FloatingDesktopTypography.firstVisible([line.readingSurfaceText, line.originalText]) ?? ""
        let primary = FloatingDesktopTypography.firstVisible([
            preferences.showOriginal ? original : nil,
            preferences.showTranslation ? line.translationText : nil, kana, reading
        ]) ?? ""
        let next = preferences.showOriginal && rows.indices.contains(index + 1) ? rows[index + 1].originalText : nil
        let chosen: String? = {
            switch settings.floatingDesktopCompanion {
            case "next": return next
            case "kana": return kana
            case "reading": return reading
            default: return preferences.showTranslation ? line.translationText : nil
            }
        }()
        let companion = FloatingDesktopTypography.companion(mode: FloatingDesktopLineMode(rawValue: settings.floatingDesktopLineMode) ?? .double,
            translation: chosen == primary ? nil : chosen, next: next)
        let fontSize = FloatingDesktopTypography.fittedFontSize(requested: settings.floatingDesktopFontSize,
            height: height, doubleLine: companion != nil)
        let elapsed = reduceMotion || state.liveCurrentLineIndex == nil ? 0 : state.currentTime - line.timestamp
        let end = line.endTime ?? (rows.indices.contains(index + 1) ? rows[index + 1].timestamp : state.currentTrack.duration)
        let duration = max(1, end - line.timestamp)
        let segments = primary == line.originalText && state.liveCurrentLineIndex != nil
            ? FloatingDesktopTypography.segments(line: line, currentTime: state.currentTime) : nil
        let primaryText = segments?.reduce(Text("")) { result, segment in
            result + Text(segment.text).foregroundColor(segment.isHighlighted ? desktopAccent : .white)
        } ?? Text(primary).foregroundColor(state.liveCurrentLineIndex == nil ? .white : desktopAccent)
        return VStack(spacing: 7) {
            FloatingDesktopRibbon(label: primary, width: width, height: fontSize * 1.3,
                elapsed: elapsed, duration: duration) {
                outlined(primaryText.font(.system(size: fontSize, weight: .bold, design: .rounded)))
            }
            if let companion, companion != primary {
                FloatingDesktopRibbon(label: companion, width: width, height: fontSize * 0.85,
                    elapsed: elapsed, duration: duration) {
                    outlined(Text(companion).font(.system(size: fontSize * 0.66, weight: .semibold, design: .rounded)).foregroundColor(.white))
                }
            }
        }
        .frame(width: width, alignment: .center)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .frame(maxHeight: .infinity, alignment: .center)
        .id("desktop-\(state.liveLyricsSessionRevision)-\(index)")
    }

    private func outlined(_ text: Text) -> some View {
        text
            .shadow(color: .black, radius: 0.6, x: -1.2, y: 0)
            .shadow(color: .black, radius: 0.6, x: 1.2, y: 0)
            .shadow(color: .black, radius: 0.6, x: 0, y: -1.2)
            .shadow(color: .black, radius: 0.6, x: 0, y: 1.2)
            .shadow(color: .black.opacity(0.75), radius: 3, y: 2)
    }

    @ViewBuilder
    private func synchronizedRows(_ rows: [LyricLine], width: CGFloat, followingCount: Int) -> some View {
        let selection = FloatingLyricsPresentationHelper.selection(
            lines: rows,
            currentIndex: state.liveCurrentLineIndex,
            isSynchronized: state.liveLyricsAreSynchronized,
            isPlaying: state.isPlaying,
            followingCount: followingCount
        )
        let visibleLayerCount = visibleLayerCount

        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(selection.visibleIndices, id: \.self) { index in
                        let distance = selection.currentIndex.map { abs(index - $0) } ?? 0
                        LyricLineView(
                            line: rows[index],
                            isActive: index == selection.currentIndex,
                            distance: distance,
                            isSynchronized: true,
                            preferences: desktopPreferences,
                            availableWidth: width,
                            visibleLayerCount: visibleLayerCount,
                            language: state.liveLyricsLanguage
                        )
                        .shadow(color: .black.opacity(0.95), radius: 2, y: 1)
                        .shadow(color: .black.opacity(0.65), radius: 5, y: 1)
                        .id(rows[index].id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.automatic)
            // A new live session replaces this scroll surface directly; old
            // rows must never animate into a newly selected track.
            .id("lyrics-document-\(state.liveLyricsSessionRevision)")
            .onChange(of: selection.currentIndex) { _, index in
                guard let index, selection.autoScroll else { return }
                LyricsTransitionPolicy.perform(reduceMotion: reduceMotion) {
                    proxy.scrollTo(rows[index].id, anchor: .top)
                }
            }
            .onChange(of: state.preferences) { _, _ in
                guard let index = selection.currentIndex else { return }
                LyricsTransitionPolicy.perform(reduceMotion: reduceMotion) {
                    proxy.scrollTo(rows[index].id, anchor: .top)
                }
            }
            .task {
                guard let index = selection.currentIndex else { return }
                proxy.scrollTo(rows[index].id, anchor: .top)
            }
        }
    }

    @ViewBuilder
    private func plainRows(_ rows: [LyricLine], width: CGFloat, status: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(status)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 7) {
                    ForEach(rows) { line in
                        LyricLineView(
                            line: line,
                            isActive: false,
                            distance: 0,
                            isSynchronized: false,
                            preferences: desktopPreferences,
                            availableWidth: width,
                            visibleLayerCount: visibleLayerCount,
                            language: state.liveLyricsLanguage
                        )
                        .shadow(color: .black.opacity(0.95), radius: 2, y: 1)
                        .shadow(color: .black.opacity(0.65), radius: 5, y: 1)
                        .id(line.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.automatic)
        }
    }

    @ViewBuilder
    private func statusView(_ state: LyricsLoadState) -> some View {
        FloatingLyricsStatusView(
            state: state,
            message: self.state.liveLyricsStatusMessage,
            title: self.state.currentTrack.title
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // Keep the shared layer and reading preferences, but bound the desktop
    // type scale independently of the much larger main-window lyric stage.
    private var desktopPreferences: DisplayPreferences {
        var preferences = state.preferences
        preferences.fontSize = min(20, max(12.6, preferences.fontSize * 0.8))
        preferences.assistantFontSize = min(16, max(11, preferences.assistantFontSize))
        return preferences
    }

    private var visibleLayerCount: Int {
        let prefs = state.preferences
        var count = prefs.showOriginal ? 1 : 0
        count += prefs.showTranslation ? 1 : 0
        count += prefs.showRomaji ? 1 : 0
        count += prefs.showKana ? 1 : 0
        return max(1, count)
    }
}

/// Each layer is one measured horizontal ribbon. Shared playback position
/// reveals overflow; dragging lets a paused listener inspect either end.
private struct FloatingDesktopRibbon<Content: View>: View {
    let label: String
    let width: CGFloat
    let height: CGFloat
    let elapsed: Double
    let duration: Double
    @ViewBuilder let content: () -> Content
    @State private var measuredWidth: CGFloat = 0
    @State private var manualOffset: CGFloat?
    @State private var dragOrigin: CGFloat?

    private var automaticOffset: CGFloat {
        FloatingDesktopTypography.ribbonOffset(textWidth: measuredWidth, viewport: width, elapsed: elapsed, duration: duration)
    }
    private var offset: CGFloat {
        min(max(0, measuredWidth - width), max(0, manualOffset ?? automaticOffset))
    }
    var body: some View {
        content()
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .background(GeometryReader { geometry in
                Color.clear.preference(key: FloatingRibbonWidthKey.self, value: geometry.size.width)
            })
            .offset(x: measuredWidth > width ? -offset : max(0, (width - measuredWidth) / 2))
            .frame(width: width, height: height, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .onPreferenceChange(FloatingRibbonWidthKey.self) { measuredWidth = $0 }
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { value in
                    if dragOrigin == nil { dragOrigin = manualOffset ?? automaticOffset }
                    manualOffset = min(max(0, measuredWidth - width), max(0, (dragOrigin ?? 0) - value.translation.width))
                }
                .onEnded { _ in dragOrigin = nil })
            .help("长句可左右拖动查看")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}
private struct FloatingRibbonWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

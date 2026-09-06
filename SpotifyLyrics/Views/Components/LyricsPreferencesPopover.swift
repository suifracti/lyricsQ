import SwiftUI

struct LyricsPreferencesPopover: View {
    @Binding var preferences: DisplayPreferences
    @ObservedObject var playbackState: PlaybackState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("歌词显示")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(LyricsDesignTokens.primaryText)
                Text("只显示需要的语言层级")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(LyricsDesignTokens.mutedText)
            }

            VStack(spacing: 10) {
                preferenceToggle("原文", systemImage: "textformat", isOn: $preferences.showOriginal)
                preferenceToggle("翻译", systemImage: "character.bubble", isOn: $preferences.showTranslation)
                preferenceToggle("罗马音", systemImage: "textformat.abc", isOn: $preferences.showRomaji)
                kanaDisplayControls
            }

            Divider().overlay(LyricsDesignTokens.controlBorder)
            LyricsPresentationOffsetControl(settings: AppSettingsStore.shared)

            Divider().overlay(LyricsDesignTokens.controlBorder)

            VStack(alignment: .leading, spacing: 10) {
                Text("显示窗口")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(LyricsDesignTokens.mutedText)

                modeButton("悬浮歌词", systemImage: "rectangle.on.rectangle", isActive: playbackState.showFloatingWindow) {
                    WindowManager.shared.toggleFloatingLyrics(state: playbackState)
                }
                modeButton("顶部胶囊", systemImage: "capsule", isActive: playbackState.showCapsulePlayer) {
                    WindowManager.shared.toggleCapsule(state: playbackState)
                }
                modeButton("全屏歌词", systemImage: "arrow.up.left.and.arrow.down.right", isActive: playbackState.showFullScreen) {
                    WindowManager.shared.toggleFullScreen(state: playbackState)
                }
            }
        }
        .padding(22)
        .frame(width: 344)
        .background(.ultraThinMaterial)
        .preferredColorScheme(.dark)
    }

    private var kanaDisplayControls: some View {
        VStack(alignment: .leading, spacing: 7) {
            preferenceToggle("假名", systemImage: "character.book.closed", isOn: $preferences.showKana)

            Picker("假名显示方式", selection: kanaDisplayModeBinding) {
                Text("独立行").tag(KanaDisplayMode.independentLine)
                Text("汉字上方").tag(KanaDisplayMode.inlineRuby)
                Text("假名替换").tag(KanaDisplayMode.kanaReplacement)
            }
            .pickerStyle(.radioGroup)
            .font(.system(size: 12, design: .rounded))
            .accessibilityLabel("假名显示方式")

            Text(preferences.kanaDisplayMode.detail)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(LyricsDesignTokens.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var kanaDisplayModeBinding: Binding<KanaDisplayMode> {
        Binding(
            get: {
                preferences.kanaDisplayMode == .hidden
                    ? .independentLine
                    : preferences.kanaDisplayMode
            },
            set: { mode in
                // Choosing any of the three presentations is sufficient to
                // enable that presentation; none is gated by the old Boolean.
                preferences.kanaDisplayMode = mode
            }
        )
    }

    private func preferenceToggle(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(LyricsDesignTokens.secondaryText)
        }
        .toggleStyle(.switch)
        .tint(LyricsDesignTokens.accent)
    }

    private func modeButton(_ title: String, systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                Text(title)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .foregroundStyle(LyricsDesignTokens.accent)
                }
            }
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(LyricsDesignTokens.secondaryText)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// One shared presentation offset editor used by the main preferences,
/// settings center, and floating desktop inspector. It only changes the
/// lyric presentation clock; it never seeks Spotify or edits LRC timestamps.
struct LyricsPresentationOffsetControl: View {
    @ObservedObject var settings: AppSettingsStore
    @State private var input = ""

    private var offset: Double {
        min(10, max(-10, settings.lyricsPresentationOffset))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("歌词时间偏移", systemImage: "clock.arrow.2.circlepath")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                Spacer()
                Text(label)
                    .font(.system(size: 11, design: .rounded).monospacedDigit())
                    .foregroundStyle(LyricsDesignTokens.secondaryText)
            }
            HStack(spacing: 6) {
                Button("提前 0.10s") { adjust(-0.1) }
                Button("延后 0.10s") { adjust(0.1) }
                TextField("秒", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 66)
                    .onSubmit { commitInput() }
                Button("归零") { settings.lyricsPresentationOffset = 0 }
                    .disabled(abs(offset) < 0.0001)
            }
            .font(.system(size: 11, design: .rounded))
            Text("只影响当前歌词的显示、自动滚动和逐字高亮，不改变播放进度。")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(LyricsDesignTokens.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { syncInput() }
        .onChange(of: settings.lyricsPresentationOffset) { _, _ in syncInput() }
    }

    private var label: String {
        if abs(offset) < 0.005 { return "0.00s" }
        return offset < 0 ? "提前 \(String(format: "%.2f", abs(offset)))s" : "延后 \(String(format: "%.2f", offset))s"
    }

    private func adjust(_ delta: Double) {
        settings.lyricsPresentationOffset = min(10, max(-10, offset + delta))
    }

    private func commitInput() {
        guard let value = Double(input.replacingOccurrences(of: ",", with: ".")), value.isFinite else {
            syncInput()
            return
        }
        settings.lyricsPresentationOffset = min(10, max(-10, value))
    }

    private func syncInput() {
        input = String(format: "%.2f", offset)
    }
}

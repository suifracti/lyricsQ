import SwiftUI

struct LyricsAndTextSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @State private var isAdvancedReadingExpanded = false
    @State private var dictionaryEntries: [ReadingDictionaryEntry] = []
    @State private var newSurface = ""
    @State private var newReading = ""
    @State private var newLanguage: ReadingLanguage = .japanese
    @State private var newTrackScope = ""
    @State private var newArtistScope = ""
    @State private var newPriority = "0"
    @State private var newNotes = ""

    var body: some View {
        Form {
            SettingsPageHeader(
                title: "歌词与文字",
                detail: "管理歌词语言层、排版与读音显示。"
            )

            Section("语言层与文字显示") {
                Toggle("显示原文", isOn: displayBinding(\.showOriginal))
                Toggle("显示翻译", isOn: displayBinding(\.showTranslation))
                Toggle("显示罗马音", isOn: displayBinding(\.showRomaji))
                Toggle("显示拼音", isOn: displayBinding(\.showPinyin))
                Picker("假名显示模式", selection: displayBinding(\.kanaDisplayMode)) {
                    Text("汉字上方注音").tag(KanaDisplayMode.inlineRuby)
                    Text("独立假名行").tag(KanaDisplayMode.independentLine)
                    Text("假名替换").tag(KanaDisplayMode.kanaReplacement)
                    Text("隐藏").tag(KanaDisplayMode.hidden)
                }
                Text(settings.displayPreferences.kanaDisplayMode.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("默认读音层", selection: readingBinding(\.japaneseRepresentationID)) {
                    Text("假名").tag(ReadingRepresentationID.kana.rawValue)
                    Text("罗马音").tag(ReadingRepresentationID.romaji.rawValue)
                }
                Picker("拼音格式", selection: readingBinding(\.pinyinRepresentationID)) {
                    Text("声调符号").tag(ReadingRepresentationID.pinyinToneMarks.rawValue)
                    Text("声调数字").tag(ReadingRepresentationID.pinyinToneNumbers.rawValue)
                    Text("无声调").tag(ReadingRepresentationID.pinyinPlain.rawValue)
                }
                Picker("繁简转换", selection: readingBinding(\.scriptConversionID)) {
                    Text("不转换").tag(ScriptConversionID.none.rawValue)
                    Text("繁体转简体").tag(ScriptConversionID.traditionalToSimplified.rawValue)
                    Text("简体转繁体").tag(ScriptConversionID.simplifiedToTraditional.rawValue)
                }
                Text("转换只影响显示层，不修改原文、歌词版本或翻译。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("字号与层级") {
                numericSlider("当前歌词字号", value: doubleBinding(\.fontSize), range: 14...42, format: "%.0f pt")
                numericSlider("辅助文本字号", value: doubleBinding(\.assistantFontSize), range: 10...24, format: "%.0f pt")
                numericSlider("Ruby 假名大小", value: doubleBinding(\.rubyFontSize), range: 8...18, format: "%.0f pt")
                numericSlider("非当前歌词透明度", value: displayBinding(\.opacity), range: 0.15...1, format: "%.0f%%", scale: 100)
                Toggle("远处歌词隐藏辅助文本", isOn: displayBinding(\.hideDistantAuxiliary))
            }

            Section {
                DisclosureGroup("读音生成与用户词典", isExpanded: $isAdvancedReadingExpanded) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("生成策略")
                                .font(.subheadline.weight(.semibold))
                            Toggle("自动生成新歌词读音", isOn: readingBinding(\.automaticGeneration))
                            Toggle("允许 AI 辅助候选（仅明确调用）", isOn: readingBinding(\.aiAssistedCandidate))
                            Picker("不确定读音策略", selection: readingBinding(\.uncertaintyPolicy)) {
                                ForEach(ReadingUncertaintyPolicy.allCases, id: \.self) { policy in
                                    Text(policy.displayName).tag(policy)
                                }
                            }
                            Text("当前版本只使用本地引擎生成；不会因浏览设置而发送 AI 请求。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户人工词典")
                                .font(.subheadline.weight(.semibold))
                            if dictionaryEntries.isEmpty {
                                Text("暂无人工词条")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(dictionaryEntries) { entry in
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text(entry.surface)
                                            Image(systemName: "arrow.right")
                                                .foregroundStyle(.secondary)
                                            Text(entry.reading)
                                            Spacer()
                                            Text(entry.language.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        HStack(spacing: 8) {
                                            if let artistScope = entry.artistScope, !artistScope.isEmpty {
                                                Text("歌手：\(artistScope)")
                                            }
                                            if let trackStableKey = entry.trackStableKey, !trackStableKey.isEmpty {
                                                Text("单曲范围")
                                            }
                                            Text("优先级 \(entry.priority)")
                                            if !entry.notes.isEmpty {
                                                Text(entry.notes)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            Button(entry.isArchived ? "恢复" : "归档") {
                                                settings.readingUserDictionary.upsert(
                                                    ReadingDictionaryEntry(
                                                        id: entry.id,
                                                        surface: entry.surface,
                                                        reading: entry.reading,
                                                        language: entry.language,
                                                        trackStableKey: entry.trackStableKey,
                                                        artistScope: entry.artistScope,
                                                        priority: entry.priority,
                                                        isEnabled: entry.isEnabled,
                                                        isArchived: !entry.isArchived,
                                                        notes: entry.notes
                                                    )
                                                )
                                                reloadDictionary()
                                            }
                                            .buttonStyle(.borderless)
                                            Button("删除", role: .destructive) {
                                                settings.readingUserDictionary.remove(id: entry.id)
                                                reloadDictionary()
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }

                            HStack {
                                TextField("原词", text: $newSurface)
                                TextField("读音", text: $newReading)
                                Picker("语言", selection: $newLanguage) {
                                    Text("日语").tag(ReadingLanguage.japanese)
                                    Text("简中").tag(ReadingLanguage.simplifiedChinese)
                                    Text("繁中").tag(ReadingLanguage.traditionalChinese)
                                }
                                .labelsHidden()
                                TextField("优先级", text: $newPriority)
                                    .frame(width: 52)
                                Button("添加") {
                                    let surface = newSurface.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let reading = newReading.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !surface.isEmpty, !reading.isEmpty else { return }
                                    settings.readingUserDictionary.upsert(
                                        ReadingDictionaryEntry(
                                            surface: surface,
                                            reading: reading,
                                            language: newLanguage,
                                            trackStableKey: newTrackScope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newTrackScope,
                                            artistScope: newArtistScope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newArtistScope,
                                            priority: Int(newPriority) ?? 0,
                                            notes: newNotes
                                        )
                                    )
                                    newSurface = ""
                                    newReading = ""
                                    newTrackScope = ""
                                    newArtistScope = ""
                                    newPriority = "0"
                                    newNotes = ""
                                    reloadDictionary()
                                }
                                .disabled(newSurface.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newReading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            HStack {
                                TextField("可选 Spotify stableKey", text: $newTrackScope)
                                TextField("可选歌手范围", text: $newArtistScope)
                                TextField("备注", text: $newNotes)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { reloadDictionary() }
    }

    private func displayBinding<Value>(_ keyPath: WritableKeyPath<DisplayPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { settings.displayPreferences[keyPath: keyPath] },
            set: { value in
                var next = settings.displayPreferences
                next[keyPath: keyPath] = value
                settings.displayPreferences = next
            }
        )
    }

    private func doubleBinding(_ keyPath: WritableKeyPath<DisplayPreferences, CGFloat>) -> Binding<Double> {
        Binding(
            get: { Double(settings.displayPreferences[keyPath: keyPath]) },
            set: { value in
                var next = settings.displayPreferences
                next[keyPath: keyPath] = CGFloat(value)
                settings.displayPreferences = next
            }
        )
    }

    private func readingBinding<Value>(_ keyPath: WritableKeyPath<ReadingPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { settings.readingPreferences[keyPath: keyPath] },
            set: { value in
                var next = settings.readingPreferences
                next[keyPath: keyPath] = value
                settings.readingPreferences = next
            }
        )
    }

    private func numericSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        scale: Double = 1
    ) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue * scale))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .trailing)
        }
    }

    private func reloadDictionary() {
        dictionaryEntries = settings.readingUserDictionary.load()
    }
}

/// Compatibility wrapper for any external/legacy callers
struct ReadingSettingsView: View {
    var body: some View {
        LyricsAndTextSettingsView()
    }
}

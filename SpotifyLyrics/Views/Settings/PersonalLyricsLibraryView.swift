import SwiftUI

public struct PersonalLyricsLibraryView: View {
    @StateObject private var service = PersonalLyricsLibraryService()
    @State private var selectedStableKey: String?

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("本地个人歌词库")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            service.exportPersonalData()
                        } label: {
                            Label("导出个人数据", systemImage: "archivebox")
                        }
                        .help("导出全部个人歌词资产")

                        Button {
                            service.presentPersonalDataImportDialog()
                        } label: {
                            Label("导入个人数据", systemImage: "shippingbox")
                        }
                        .help("导入标准个人数据包并先查看冲突")

                        Button {
                            service.presentImportDialog()
                        } label: {
                            Label("导入资产包", systemImage: "square.and.arrow.down")
                        }
                        .help("导入 .lyricisland.json 歌词资产包")

                        Button {
                            service.refresh()
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                        .help("刷新歌词库")
                    }
                }
        } detail: {
            if let stableKey = selectedStableKey {
                PersonalLibraryTrackDetailView(service: service, stableKey: stableKey)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("选择左侧歌曲查看资产版本")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("管理你采用、编辑、生成的歌词、翻译、读音与逐字时间轴")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $service.showImportPreviewSheet) {
            if let preview = service.importPreview {
                PersonalLibraryImportPreviewSheet(preview: preview, onConfirm: {
                    service.confirmImport()
                }, onCancel: {
                    service.cancelImport()
                })
            }
        }
        .sheet(isPresented: $service.showDataImportPreviewSheet) {
            if let preview = service.dataImportPreview {
                PersonalDataImportPreviewSheet(preview: preview, onConfirm: {
                    service.confirmPersonalDataImport()
                }, onCancel: {
                    service.cancelPersonalDataImport()
                })
            }
        }
        .onAppear {
            service.refresh()
        }
    }

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索歌名、歌手或专辑...", text: $service.searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        service.refresh()
                    }
                if !service.searchQuery.isEmpty {
                    Button {
                        service.searchQuery = ""
                        service.refresh()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !service.statusMessage.isEmpty {
                HStack {
                    Text(service.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }

            syncFolderSection

            Divider()

            if service.entries.isEmpty && !service.isLoading {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("暂无本地歌词资产")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("当你采用翻译、生成读音、编辑歌词或锁定版本后，会自动收录至此。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                List(service.entries, selection: $selectedStableKey) { entry in
                    PersonalLibraryEntryRow(entry: entry)
                        .tag(entry.trackStableKey)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 280)
    }

    private var syncFolderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("同步文件夹", systemImage: "folder")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("选择") {
                    service.selectSyncFolder()
                }
            }

            if let folder = service.syncFolderURL {
                Text(folder.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Button {
                        service.syncNow()
                    } label: {
                        Label(
                            service.isSyncing ? "检查中..." : "同步现在",
                            systemImage: service.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(service.isSyncing)

                    Button("取消同步") {
                        service.cancelSyncFolder()
                    }
                }
            } else {
                Text("尚未设置私人同步文件夹")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
    }
}

private struct PersonalLibraryEntryRow: View {
    let entry: PersonalLyricsLibraryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                // Artwork thumbnail
                AsyncImage(url: entry.artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Text(entry.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let album = entry.album, !album.isEmpty {
                        Text(album)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            // Asset Badges
            HStack(spacing: 6) {
                if entry.lyricsVersionCount > 0 {
                    AssetBadge(
                        title: "歌词",
                        icon: entry.hasLockedLyrics ? "lock.fill" : (entry.hasManualLyrics ? "pencil" : nil),
                        color: .blue
                    )
                }
                if entry.translationVersionCount > 0 {
                    AssetBadge(
                        title: "翻译",
                        icon: entry.hasLockedTranslation ? "lock.fill" : (entry.hasManualTranslation ? "pencil" : nil),
                        color: .green
                    )
                }
                if entry.hasReading {
                    AssetBadge(
                        title: "读音",
                        icon: nil,
                        color: .orange
                    )
                }
                if entry.hasFineTiming {
                    AssetBadge(
                        title: "逐字",
                        icon: nil,
                        color: .purple
                    )
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AssetBadge: View {
    let title: String
    let icon: String?
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Track Detail View

public struct PersonalLibraryTrackDetailView: View {
    @ObservedObject var service: PersonalLyricsLibraryService
    let stableKey: String

    public var body: some View {
        Group {
            if let detail = service.selectedTrackDetail, detail.entry.trackStableKey == stableKey {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        trackHeader(detail.entry)

                        Divider()

                        // Section 1: Lyrics Versions
                        versionSection(
                            title: "歌词版本 (\(detail.lyricsVersions.count))",
                            icon: "text.quote",
                            color: .blue
                        ) {
                            if detail.lyricsVersions.isEmpty {
                                emptyPlaceholder("暂无保存的歌词版本")
                            } else {
                                ForEach(detail.lyricsVersions) { lv in
                                    lyricsVersionCard(lv, entry: detail.entry)
                                }
                            }
                        }

                        // Section 2: Translation Versions
                        versionSection(
                            title: "翻译版本 (\(detail.translationVersions.count))",
                            icon: "character.bubble",
                            color: .green
                        ) {
                            if detail.translationVersions.isEmpty {
                                emptyPlaceholder("暂无保存的翻译版本")
                            } else {
                                ForEach(detail.translationVersions) { tv in
                                    translationVersionCard(tv, entry: detail.entry)
                                }
                            }
                        }

                        // Section 3: Reading Versions
                        versionSection(
                            title: "读音版本 (\(detail.readingVersions.count))",
                            icon: "character.book.closed",
                            color: .orange
                        ) {
                            if detail.readingVersions.isEmpty {
                                emptyPlaceholder("暂无保存的读音版本")
                            } else {
                                ForEach(detail.readingVersions) { rv in
                                    readingVersionCard(rv, entry: detail.entry)
                                }
                            }
                        }

                        // Section 4: Timing Versions
                        versionSection(
                            title: "逐字时间轴 (\(detail.timingVersions.count))",
                            icon: "waveform",
                            color: .purple
                        ) {
                            if detail.timingVersions.isEmpty {
                                emptyPlaceholder("暂无保存的逐字时间轴")
                            } else {
                                ForEach(detail.timingVersions) { tm in
                                    timingVersionCard(tm)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                VStack {
                    ProgressView()
                    Text("正在加载歌曲资产...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    service.selectTrack(stableKey: stableKey)
                }
            }
        }
        .onChange(of: stableKey) { _, newKey in
            service.selectTrack(stableKey: newKey)
        }
    }

    private func trackHeader(_ entry: PersonalLyricsLibraryEntry) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: entry.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.15))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.title2.bold())
                Text(entry.artist)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if let album = entry.album, !album.isEmpty {
                    Text(album)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                service.exportPackage(for: entry.trackStableKey)
            } label: {
                Label("导出资产包 (.lyricisland)", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    @ViewBuilder
    private func versionSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            content()
        }
    }

    private func emptyPlaceholder(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.vertical, 8)
    }

    // MARK: - Version Cards

    private func lyricsVersionCard(_ lv: PersonalLyricsVersionItem, entry: PersonalLyricsLibraryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(lv.source.uppercased())
                            .font(.system(size: 12, weight: .bold))
                        if lv.isCurrent {
                            statusTag("当前采用", color: .blue)
                        }
                        if lv.isLocked {
                            statusTag("已锁定", color: .indigo)
                        }
                        if lv.isManuallyEdited {
                            statusTag("人工编辑", color: .orange)
                        }
                        if lv.isSynced {
                            statusTag("时间轴", color: .teal)
                        }
                    }
                    Text("行数: \(lv.lineCount) · 语言: \(lv.language) · 更新于 \(formattedDate(lv.updatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if !lv.isCurrent {
                        Button("设为当前") {
                            service.adoptLyricsVersion(versionID: lv.id, trackStableKey: entry.trackStableKey)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button(lv.isLocked ? "解锁" : "锁定") {
                        service.toggleLyricsLock(versionID: lv.id, currentLocked: lv.isLocked, trackStableKey: entry.trackStableKey)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func translationVersionCard(_ tv: PersonalTranslationVersionItem, entry: PersonalLyricsLibraryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(tv.sourceKind.uppercased())
                            .font(.system(size: 12, weight: .bold))
                        if tv.isCurrent {
                            statusTag("当前采用", color: .green)
                        }
                        if tv.isLocked {
                            statusTag("已锁定", color: .indigo)
                        }
                        if tv.isArchived {
                            statusTag("已归档", color: .secondary)
                        }
                        if tv.isManuallyEdited {
                            statusTag("人工编辑", color: .orange)
                        }
                    }
                    Text("目标语言: \(tv.targetLanguage) · 行数: \(tv.lineCount) · 更新于 \(formattedDate(tv.updatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if !tv.isCurrent && !tv.isArchived {
                        Button("设为当前") {
                            service.adoptTranslation(versionID: tv.id, trackStableKey: entry.trackStableKey)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button(tv.isLocked ? "解锁" : "锁定") {
                        service.toggleTranslationLock(versionID: tv.id, currentLocked: tv.isLocked, trackStableKey: entry.trackStableKey)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(tv.isArchived ? "恢复" : "归档") {
                        service.toggleTranslationArchive(versionID: tv.id, currentArchived: tv.isArchived, trackStableKey: entry.trackStableKey)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func readingVersionCard(_ rv: PersonalReadingVersionItem, entry: PersonalLyricsLibraryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(rv.representationID.contains("kana") ? "假名 (KANA)" : "罗马音 (ROMAJI)")
                            .font(.system(size: 12, weight: .bold))
                        if rv.isCurrent {
                            statusTag("当前采用", color: .orange)
                        }
                        if rv.isLocked {
                            statusTag("已锁定", color: .indigo)
                        }
                        if rv.isArchived {
                            statusTag("已归档", color: .secondary)
                        }
                    }
                    Text("来源: \(rv.sourceKind) · 行数: \(rv.lineCount) · 更新于 \(formattedDate(rv.updatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if !rv.isCurrent && !rv.isArchived {
                        Button("设为当前") {
                            service.adoptReading(versionID: rv.id, trackStableKey: entry.trackStableKey)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button(rv.isLocked ? "解锁" : "锁定") {
                        service.toggleReadingLock(versionID: rv.id, currentLocked: rv.isLocked, trackStableKey: entry.trackStableKey)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(rv.isArchived ? "恢复" : "归档") {
                        service.toggleReadingArchive(versionID: rv.id, currentArchived: rv.isArchived, trackStableKey: entry.trackStableKey)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func timingVersionCard(_ tm: PersonalTimingVersionItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tm.source.uppercased())
                    .font(.system(size: 12, weight: .bold))
                if tm.isCurrent {
                    statusTag("当前", color: .purple)
                }
                statusTag(tm.granularity, color: .secondary)
                Spacer()
                Text(formattedDate(tm.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func statusTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Import Preview Sheet

public struct PersonalLibraryImportPreviewSheet: View {
    let preview: PersonalLibraryImportPreview
    let onConfirm: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("导入歌词资产包预览")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("歌曲：\(preview.trackTitle) - \(preview.trackArtist)")
                    .font(.subheadline.bold())
                Text("资产新增统计：")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    summaryItem(title: "歌词版本", add: preview.lyricsToAdd, skip: preview.lyricsToSkip)
                    summaryItem(title: "翻译版本", add: preview.translationsToAdd, skip: preview.translationsToSkip)
                    summaryItem(title: "读音版本", add: preview.readingsToAdd, skip: preview.readingsToSkip)
                    summaryItem(title: "逐字时间轴", add: preview.timingsToAdd, skip: preview.timingsToSkip)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            if preview.hasConflicts {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("发现版本冲突")
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                    }
                    Text("存在相同版本 ID 但内容不一致的资产，已阻止静默覆盖：")
                        .font(.caption)
                    ForEach(preview.allConflicts, id: \.self) { c in
                        Text("• \(c)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack {
                Spacer()
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("确认导入") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(preview.hasConflicts || preview.totalNewAssets == 0)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 420)
    }

    private func summaryItem(title: String, add: Int, skip: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
            Text("新增: \(add) · 跳过: \(skip)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Standard Personal Data Preview Sheet

public struct PersonalDataImportPreviewSheet: View {
    let preview: PersonalDataImportPreview
    let onConfirm: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("导入个人数据预览")
                .font(.headline)

            Text("包含 " + String(preview.trackCount) + " 首歌曲，新增 " + String(preview.totalNewAssets) + " 项个人资产")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if preview.trackPreviews.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("此数据包不包含个人歌词资产")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(preview.trackPreviews, id: \.trackStableKey) { trackPreview in
                            trackSummary(trackPreview)
                        }
                    }
                }
                .frame(minHeight: 180)
            }

            HStack {
                Spacer()
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("确认导入") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(preview.hasConflicts || preview.totalNewAssets == 0)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 360)
    }

    private func trackSummary(_ trackPreview: PersonalLibraryImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trackPreview.trackTitle + " — " + trackPreview.trackArtist)
                .font(.subheadline.bold())

            HStack(spacing: 12) {
                summaryItem(title: "歌词", add: trackPreview.lyricsToAdd, skip: trackPreview.lyricsToSkip)
                summaryItem(title: "翻译", add: trackPreview.translationsToAdd, skip: trackPreview.translationsToSkip)
                summaryItem(title: "读音", add: trackPreview.readingsToAdd, skip: trackPreview.readingsToSkip)
                summaryItem(title: "逐字时间轴", add: trackPreview.timingsToAdd, skip: trackPreview.timingsToSkip)
            }

            if trackPreview.hasConflicts {
                VStack(alignment: .leading, spacing: 3) {
                    Text("发现冲突，已阻止静默覆盖")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    ForEach(trackPreview.allConflicts, id: \.self) { conflict in
                        Text("• " + conflict)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func summaryItem(title: String, add: Int, skip: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
            Text("新增: " + String(add) + " · 跳过: " + String(skip))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(5)
    }
}

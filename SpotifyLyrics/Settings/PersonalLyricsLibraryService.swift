import Foundation
import AppKit
import Combine

@MainActor
public final class PersonalLyricsLibraryService: ObservableObject {
    @Published public private(set) var entries: [PersonalLyricsLibraryEntry] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var statusMessage: String = ""
    @Published public var searchQuery: String = ""

    @Published public var selectedTrackDetail: PersonalLyricsLibraryTrackDetail?
    @Published public var importPreview: PersonalLibraryImportPreview?
    @Published public var pendingImportPackage: PersonalLyricsLibraryPackage?
    @Published public var showImportPreviewSheet = false

    private let repository: SQLiteLyricsRepository

    public init(repository: SQLiteLyricsRepository = SQLiteLyricsRepository()) {
        self.repository = repository
    }

    public func refresh() {
        isLoading = true
        statusMessage = "正在加载歌词库..."
        let query = searchQuery
        Task {
            do {
                let list = try await repository.loadPersonalLibraryEntries(searchQuery: query.isEmpty ? nil : query)
                self.entries = list
                self.isLoading = false
                self.statusMessage = list.isEmpty ? "个人歌词库为空" : "共 \(list.count) 首本地资产歌曲"
            } catch {
                self.isLoading = false
                self.statusMessage = "加载失败：\(error.localizedDescription)"
            }
        }
    }

    public func selectTrack(stableKey: String) {
        Task {
            do {
                if let detail = try await repository.loadPersonalLibraryTrackDetail(stableKey: stableKey) {
                    self.selectedTrackDetail = detail
                }
            } catch {
                self.statusMessage = "获取歌曲详情失败：\(error.localizedDescription)"
            }
        }
    }

    // MARK: - Version Actions

    public func adoptLyricsVersion(versionID: UUID, trackStableKey: String) {
        Task {
            do {
                try await repository.setPersonalLibraryActiveLyrics(trackStableKey: trackStableKey, lyricsVersionID: versionID)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "切换歌词版本失败：\(error.localizedDescription)"
            }
        }
    }

    public func toggleLyricsLock(versionID: UUID, currentLocked: Bool, trackStableKey: String) {
        Task {
            do {
                try await repository.toggleLyricsLocked(versionID: versionID, locked: !currentLocked)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "锁定歌词失败：\(error.localizedDescription)"
            }
        }
    }

    public func adoptTranslation(versionID: UUID, trackStableKey: String) {
        Task {
            do {
                try await repository.adoptTranslation(versionID: versionID)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "采用翻译失败：\(error.localizedDescription)"
            }
        }
    }

    public func toggleTranslationLock(versionID: UUID, currentLocked: Bool, trackStableKey: String) {
        Task {
            do {
                try await repository.markTranslationLocked(versionID: versionID, locked: !currentLocked)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "锁定翻译失败：\(error.localizedDescription)"
            }
        }
    }

    public func toggleTranslationArchive(versionID: UUID, currentArchived: Bool, trackStableKey: String) {
        Task {
            do {
                try await repository.archiveTranslation(versionID: versionID, archived: !currentArchived)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "归档翻译失败：\(error.localizedDescription)"
            }
        }
    }

    public func adoptReading(versionID: UUID, trackStableKey: String) {
        Task {
            do {
                try await repository.adoptReadingVersion(versionID: versionID)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "采用读音失败：\(error.localizedDescription)"
            }
        }
    }

    public func toggleReadingLock(versionID: UUID, currentLocked: Bool, trackStableKey: String) {
        Task {
            do {
                try await repository.markReadingLocked(versionID: versionID, locked: !currentLocked)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "锁定读音失败：\(error.localizedDescription)"
            }
        }
    }

    public func toggleReadingArchive(versionID: UUID, currentArchived: Bool, trackStableKey: String) {
        Task {
            do {
                try await repository.archiveReadingVersion(versionID: versionID, archived: !currentArchived)
                selectTrack(stableKey: trackStableKey)
                refresh()
            } catch {
                self.statusMessage = "归档读音失败：\(error.localizedDescription)"
            }
        }
    }

    // MARK: - Export / Import

    public func exportPackage(for stableKey: String) {
        Task {
            do {
                let package = try await repository.exportPersonalLibraryPackage(stableKey: stableKey)
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(package)

                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.json]
                savePanel.nameFieldStringValue = "\(package.track.artist) - \(package.track.title).lyricisland.json"
                savePanel.title = "导出歌词资产包"
                savePanel.message = "导出包含歌词、翻译、读音与逐字时间轴的标准数据包"

                if savePanel.runModal() == .OK, let url = savePanel.url {
                    try data.write(to: url, options: .atomic)
                    self.statusMessage = "导出成功：\(url.lastPathComponent)"
                }
            } catch {
                self.statusMessage = "导出失败：\(error.localizedDescription)"
            }
        }
    }

    public func presentImportDialog() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "选择要导入的歌词资产包"

        if openPanel.runModal() == .OK, let url = openPanel.url {
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let package = try decoder.decode(PersonalLyricsLibraryPackage.self, from: data)
                    let preview = try await repository.previewImportPersonalLibraryPackage(package)

                    self.pendingImportPackage = package
                    self.importPreview = preview
                    self.showImportPreviewSheet = true
                } catch {
                    self.statusMessage = "读取歌词包失败：\(error.localizedDescription)"
                }
            }
        }
    }

    public func confirmImport() {
        guard let package = pendingImportPackage else { return }
        Task {
            do {
                try await repository.importPersonalLibraryPackage(package)
                self.statusMessage = "成功导入「\(package.track.title)」的歌词资产"
                self.pendingImportPackage = nil
                self.importPreview = nil
                self.showImportPreviewSheet = false
                refresh()
            } catch {
                self.statusMessage = "导入失败：\(error.localizedDescription)"
            }
        }
    }

    public func cancelImport() {
        self.pendingImportPackage = nil
        self.importPreview = nil
        self.showImportPreviewSheet = false
    }
}

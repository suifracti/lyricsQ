import Foundation
import SQLite3

@main struct LyricSourceProvenanceContract {
    static func main() async throws {
        for source in LyricsSource.allCases {
            precondition(DatabaseSourceIdentifier.source(for: DatabaseSourceIdentifier.identifier(for: source)) == source)
        }
        let expected = ["netEaseExperimental": "网易云音乐", "qqExperimental": "QQ音乐", "amll": "AMLL",
                        "lrclib": "LRCLIB", "manualImport": "手动导入", "manualCreate": "手动创建",
                        "lyricsOVH": "Lyrics.ovh", "kuwoExperimental": "酷我音乐", "kugouExperimental": "酷狗音乐"]
        for (identifier, label) in expected { precondition(DatabaseSourceIdentifier.displayName(for: identifier) == label) }
        precondition(DatabaseSourceIdentifier.displayName(for: "historicalProvider42") == "未知来源（historicalProvider42）")
        precondition(DatabaseSourceIdentifier.displayName(for: "localDatabase") == "本地记录（原始来源未记录）")
        let missing = DatabaseSourceIdentifier.provenanceDescription(source: "manualEdit", parentVersionID: UUID()) { _ in nil }
        precondition(missing == "原始来源未知 · 人工编辑")
        let cycle = UUID()
        precondition(DatabaseSourceIdentifier.provenanceDescription(source: "manualEdit", parentVersionID: cycle) { _ in ("manualEdit", cycle) } == missing)

        let root = FileManager.default.temporaryDirectory.appendingPathComponent("lyrics-provenance-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let path = root.appendingPathComponent("fixture.sqlite3")
        let repository = SQLiteLyricsRepository(databaseURL: path)
        try await repository.prepare()
        let track = Track(title: "Provenance fixture", artist: "Fixture", album: "Fixture", duration: 100, spotifyId: "provenance-fixture")
        let identity = TrackIdentity(track: track)
        let document = LyricsDocument(identity: identity, lines: [LyricLine(timestamp: 0, originalText: "Source lyric")],
            isSynchronized: false, source: .neteaseExperimental, providerSourceID: "netease:song:123")
        let saved = try await repository.save(track: track, identity: identity, document: document)
        let original = try await repository.loadEditableVersion(versionID: saved.versionID!, track: track, identity: identity)!
        var latest = original
        for _ in 0..<2 {
            latest = try await repository.saveManualEdit(LyricsEditSaveRequest(track: track, identity: identity,
                sourceVersionID: latest.record.id,
                sourceContentHash: LyricsSourceContentHasher.hash(isSynchronized: latest.record.isSynced, lines: latest.lines),
                document: document, createLyricsVersion: true)).lyricsVersion!
        }
        let reopened = SQLiteLyricsRepository(databaseURL: path)
        try await reopened.prepare()
        let detail = try await reopened.loadPersonalLibraryTrackDetail(stableKey: identity.stableKey)!
        let child = detail.lyricsVersions.first { $0.id == latest.record.id }!
        let provenance = DatabaseSourceIdentifier.provenanceDescription(source: child.source, parentVersionID: child.parentVersionID) { id in
            guard let parent = detail.lyricsVersions.first(where: { $0.id == id }) else { return nil }
            return (parent.source, parent.parentVersionID)
        }
        precondition(provenance == "网易云音乐 · 人工编辑", "Provider ancestry must survive multiple revisions and repository reload")
        let unchanged = try await reopened.loadEditableVersion(versionID: original.record.id, track: track, identity: identity)!
        precondition(unchanged.record == original.record && unchanged.lines == original.lines)
        precondition(unchanged.record.source == "netEaseExperimental" && unchanged.record.providerSourceID == "netease:song:123")

        // Simulate a historical provider no longer present in the enum. The raw
        // database source remains intact and is never presented as local LRC.
        var handle: OpaquePointer?
        precondition(sqlite3_open(path.path, &handle) == SQLITE_OK)
        precondition(sqlite3_exec(handle, "UPDATE lyrics_versions SET source='historicalProvider42' WHERE id='\(original.record.id.uuidString)'", nil, nil, nil) == SQLITE_OK)
        sqlite3_close(handle)
        let historicalRepository = SQLiteLyricsRepository(databaseURL: path)
        try await historicalRepository.prepare()
        let historical = try await historicalRepository.loadEditableVersion(versionID: original.record.id, track: track, identity: identity)!
        precondition(historical.record.source == "historicalProvider42")
        precondition(DatabaseSourceIdentifier.displayName(for: historical.record.source) == "未知来源（historicalProvider42）")
        precondition(historical.document.source.displayName == "未知来源")
        let historicalDetail = try await historicalRepository.loadPersonalLibraryTrackDetail(stableKey: identity.stableKey)!
        let historicalAncestry = DatabaseSourceIdentifier.provenanceDescription(source: child.source, parentVersionID: child.parentVersionID) { id in
            guard let parent = historicalDetail.lyricsVersions.first(where: { $0.id == id }) else { return nil }
            return (parent.source, parent.parentVersionID)
        }
        precondition(historicalAncestry == "未知来源（historicalProvider42） · 人工编辑")
        print("Lyric source provenance contract PASS")
    }
}

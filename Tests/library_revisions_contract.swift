import Foundation
import SQLite3
@main struct LibraryRevisionsContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("library-revisions-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("test.sqlite3"), alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
        try await repo.prepare()
        let track = Track(title: "Revision fixture", artist: "Test", album: "Test", duration: 100, spotifyId: "revision-test")
        let identity = TrackIdentity(track: track)
        let original = LyricsDocument(identity: identity, title: track.title, artist: track.artist, album: track.album, duration: 100, lines: [LyricLine(timestamp: 1, originalText: "Original first"), LyricLine(timestamp: 4, originalText: "Original second")], isSynchronized: true, source: .lrclib, confidence: 0.9, providerSourceID: "fixture")
        let saved = try await repo.save(track: track, identity: identity, document: original)
        let source = try await repo.loadEditableVersion(versionID: saved.versionID!, track: track, identity: identity)!
        let request = LyricsEditSaveRequest(track: track, identity: identity, sourceVersionID: source.record.id, sourceContentHash: LyricsSourceContentHasher.hash(isSynchronized: source.record.isSynced, lines: source.lines), document: original, createLyricsVersion: true, lockLyricsVersion: true)
        let higher = try await repo.saveManualEdit(request).lyricsVersion!
        try await repo.setPersonalLibraryActiveLyrics(trackStableKey: identity.stableKey, lyricsVersionID: source.record.id)
        let selected = try await repo.loadBestStored(track: track, identity: identity)
        precondition(selected?.versionID == source.record.id, "Explicit original selection must beat locked/high-confidence newer versions")
        precondition(higher.record.id != source.record.id)
        var revisionDraft = LibraryLyricsRevisionDraft(track: track, source: higher)
        do { _ = try revisionDraft.saveRequest(); fatalError("No-op revision accepted") }
        catch LyricsEditingRepositoryError.noChanges { }
        revisionDraft.lines[0].originalText = "Revised first"
        let revision = try await repo.saveManualEdit(revisionDraft.saveRequest()).lyricsVersion!
        precondition(revision.record.id != source.record.id && revision.record.id != higher.record.id)
        precondition(revision.record.parentVersionID == higher.record.id)
        precondition(revision.document.lines.map(\.originalText) == ["Revised first", "Original second"])
        precondition(revision.document.lines.map(\.timestamp) == [1, 4])
        let originalAfter = try await repo.loadEditableVersion(versionID: source.record.id, track: track, identity: identity)!
        let lockedAfter = try await repo.loadEditableVersion(versionID: higher.record.id, track: track, identity: identity)!
        precondition(originalAfter.record == source.record && originalAfter.lines == source.lines)
        precondition(lockedAfter.record == higher.record && lockedAfter.lines == higher.lines)
        let stillSelected = try await repo.loadBestStored(track: track, identity: identity)
        precondition(stillSelected?.versionID == source.record.id, "Save must not adopt implicitly")
        try await repo.setPersonalLibraryActiveLyrics(trackStableKey: identity.stableKey, lyricsVersionID: revision.record.id)
        let newSelected = try await repo.loadBestStored(track: track, identity: identity)
        precondition(newSelected?.versionID == revision.record.id)
        try await repo.setPersonalLibraryActiveLyrics(trackStableKey: identity.stableKey, lyricsVersionID: source.record.id)
        let reopened = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("test.sqlite3"), alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
        try await reopened.prepare()
        let restored = try await reopened.loadBestStored(track: track, identity: identity)
        precondition(restored?.versionID == source.record.id)
        let detail = try await reopened.loadPersonalLibraryTrackDetail(stableKey: identity.stableKey)!
        precondition(detail.lyricsVersions.count == 3 && detail.lyricsVersions.first(where: \.isCurrent)?.id == source.record.id)
        do { try await repo.setPersonalLibraryActiveLyrics(trackStableKey: "wrong-track", lyricsVersionID: source.record.id); fatalError("Cross-track selection accepted") }
        catch LyricsEditingRepositoryError.identityMismatch { }
        let retained = try await repo.loadBestStored(track: track, identity: identity)
        precondition(retained?.versionID == source.record.id)
        // Current-song editor saves still adopt new content after library preference exists.
        var normal = LibraryLyricsRevisionDraft(track: track, source: revision)
        normal.lines[0].originalText = "Normal editor revision"
        let prepared = try normal.saveRequest()
        let normalRequest = LyricsEditSaveRequest(track: track, identity: identity, sourceVersionID: revision.record.id, sourceContentHash: prepared.sourceContentHash, document: prepared.document, createLyricsVersion: true)
        let normalSaved = try await repo.saveManualEdit(normalRequest).lyricsVersion!
        let normalSelected = try await repo.loadBestStored(track: track, identity: identity)
        precondition(normalSelected?.versionID == normalSaved.record.id)
        // Clearing/moving start times must not retain hidden stale end times.
        var retimed = LibraryLyricsRevisionDraft(track: track, source: revision)
        retimed.lines[0].startTime = nil
        let partialRequest = try retimed.saveRequest()
        precondition(partialRequest.document.lines[0].endTime == nil)
        _ = try await repo.saveManualEdit(partialRequest)
        // Export/import retains original selection and lineage, without overriding local choice.
        try await repo.setPersonalLibraryActiveLyrics(trackStableKey: identity.stableKey, lyricsVersionID: source.record.id)
        let package = try await repo.exportPersonalLibraryPackage(stableKey: identity.stableKey)
        precondition(package.preferredLyricsVersionID == source.record.id)
        let decoded = try JSONDecoder().decode(PersonalLyricsLibraryPackage.self, from: JSONEncoder().encode(package))
        let imported = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("import.sqlite3"), alignmentProvenanceDirectory: root.appendingPathComponent("import-provenance"))
        try await imported.importPersonalLibraryPackage(decoded)
        let importedSelected = try await imported.loadBestStored(track: track, identity: identity)
        precondition(importedSelected?.versionID == source.record.id)
        let importedRevision = try await imported.loadEditableVersion(versionID: revision.record.id, track: track, identity: identity)!
        precondition(importedRevision.record.parentVersionID == higher.record.id)
        try await imported.setPersonalLibraryActiveLyrics(trackStableKey: identity.stableKey, lyricsVersionID: revision.record.id)
        try await imported.importPersonalLibraryPackage(decoded)
        let localWins = try await imported.loadBestStored(track: track, identity: identity)
        precondition(localWins?.versionID == revision.record.id)
        var handle: OpaquePointer?
        precondition(sqlite3_open(root.appendingPathComponent("import.sqlite3").path, &handle) == SQLITE_OK)
        let escapedKey = identity.stableKey.replacingOccurrences(of: "'", with: "''")
        let redirectSQL = "INSERT INTO track_identity_redirects VALUES ('historical-fixture', '\(escapedKey)', 'fixture', 'fixture', 'fixture', 1);"
        precondition(sqlite3_exec(handle, redirectSQL, nil, nil, nil) == SQLITE_OK)
        sqlite3_close(handle)
        var oldKeyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as! [String: Any]
        var oldTrack = oldKeyJSON["track"] as! [String: Any]
        oldTrack["stableKey"] = "historical-fixture"
        oldKeyJSON["track"] = oldTrack
        let oldKeyPackage = try JSONDecoder().decode(PersonalLyricsLibraryPackage.self, from: JSONSerialization.data(withJSONObject: oldKeyJSON))
        let redirected = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("import.sqlite3"), alignmentProvenanceDirectory: root.appendingPathComponent("redirect-provenance"))
        try await redirected.importPersonalLibraryPackage(oldKeyPackage)
        let redirectSelected = try await redirected.loadBestStored(track: track, identity: identity)
        precondition(redirectSelected?.versionID == revision.record.id, "Historical-key import must preserve canonical local choice")
        print("Library revisions PASS: fork/original/selection/restore/normal editor/partial timing/export import/redirect preference")
    }
}

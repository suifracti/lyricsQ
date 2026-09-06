import Foundation
import SQLite3

@main struct LibraryIdentitySearchContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("library-identity-search-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("test.sqlite3")
        let repo = SQLiteLyricsRepository(databaseURL: url, alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
        try await repo.prepare()
        func save(_ track: Track, text: String) async throws -> UUID {
            let identity = TrackIdentity(track: track)
            let document = LyricsDocument(identity: identity, title: track.title, artist: track.artist, album: track.album, duration: track.duration,
                lines: [LyricLine(timestamp: 1, originalText: text, translationText: "legacytranslation", romajiText: "legacyromaji", kanaText: "れがしーかな")],
                isSynchronized: true, source: .lrclib, confidence: 0.95, providerSourceID: text)
            return try await repo.save(track: track, identity: identity, document: document).versionID!
        }
        let a = Track(title: "Family fixture", artist: "Singer", album: "Album", duration: 170, spotifyId: "family-song")
        let b = Track(title: a.title, artist: a.artist, album: a.album, duration: 170.72, spotifyId: "family-song")
        let unrelated = Track(title: a.title, artist: a.artist, album: a.album, duration: 170, spotifyId: "different-song")
        let conflict = Track(title: a.title, artist: "Different singer", album: a.album, duration: 170, spotifyId: "family-song")
        let aID = try await save(a, text: "原版独有歌词")
        let bID = try await save(b, text: "新版独有歌词")
        _ = try await save(unrelated, text: "unrelated")
        _ = try await save(conflict, text: "conflict")
        let historical = Track(title: "Historical metadata", artist: "Historical singer", album: "Old album", duration: 99, spotifyId: "historical-id")
        let historicalID = try await save(historical, text: "historical-only")
        _ = try await save(Track(title: "Duration conflict", artist: "Singer", album: "Album", duration: 100, spotifyId: "duration-conflict"), text: "short recording")
        _ = try await save(Track(title: "Duration conflict", artist: "Singer", album: "Album", duration: 130, spotifyId: "duration-conflict"), text: "long recording")
        _ = try await save(Track(title: a.title, artist: a.artist, album: a.album, duration: a.duration), text: "metadata-only")
        var db: OpaquePointer?
        precondition(sqlite3_open(url.path, &db) == SQLITE_OK)
        let readingID = UUID(), translationID = UUID()
        let sql = """
        INSERT INTO track_identity_redirects VALUES ('\(TrackIdentity(track: historical).stableKey)', '\(TrackIdentity(track: a).stableKey)', 'fixture', 'fixture', 'fixture', 1);
        INSERT INTO reading_versions(id,lyrics_version_id,source_content_hash,engine_id,representation_id,created_at,updated_at)
        VALUES ('\(readingID)','\(bID)','fixture','fixture','readingRepresentation.kana',1,1);
        INSERT INTO reading_lines(reading_version_id,line_index,original_text,reading_text)
        VALUES ('\(readingID)',0,'新版独有歌词','からだ savedreadingneedle');
        INSERT INTO translation_versions(id,lyrics_version_id,source_kind,target_language,source_content_hash,created_at,updated_at,status)
        VALUES ('\(translationID)','\(aID)','manualEdit','zh','fixture',1,1,'complete');
        INSERT INTO translation_lines VALUES ('\(translationID)',0,'保存译文独有词');
        INSERT INTO track_aliases(track_stable_key,field,kind,value,script,source,confidence,is_official)
        VALUES ('\(TrackIdentity(track: b).stableKey)','title','userAlias','Alternative title','latin','user',1,0);
        """
        var error: UnsafeMutablePointer<CChar>?
        precondition(sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK, error.map { String(cString: $0) } ?? "fixture SQL")
        sqlite3_close(db)
        let entries = try await repo.loadPersonalLibraryEntries()
        precondition(entries.count == 6, "Same Spotify recording with subsecond duration drift must occupy one row; conflicting identities stay separate")
        let family = entries.first { $0.lyricsVersionCount == 3 }!
        let detail = try await repo.loadPersonalLibraryTrackDetail(stableKey: family.trackStableKey)!
        precondition(Set(detail.lyricsVersions.map(\.id)) == [aID, bID, historicalID], "Grouping must retain both physical keys' versions")
        precondition(detail.readingVersions.contains { $0.id == readingID } && detail.translationVersions.contains { $0.id == translationID })
        let oldDetail = try await repo.loadPersonalLibraryTrackDetail(stableKey: TrackIdentity(track: b).stableKey)!
        precondition(oldDetail.entry.trackStableKey == family.trackStableKey && oldDetail.lyricsVersions.count == 3)
        for query in ["原版独有", "新版独有", "historical-only", "SAVEDREADINGNEEDLE", "karada", "保存译文独有", "Alternative title"] {
            let found = try await repo.loadPersonalLibraryEntries(searchQuery: query)
            precondition(found.map(\.trackStableKey) == [family.trackStableKey], "Search must cover all versions and aliases: \(query)")
        }
        for query in ["legacyromaji", "れがしーかな", "legacytranslation", "Singer", "Album"] {
            let found = try await repo.loadPersonalLibraryEntries(searchQuery: query)
            precondition(found.contains { $0.trackStableKey == family.trackStableKey })
        }
        let injection = try await repo.loadPersonalLibraryEntries(searchQuery: "' OR 1=1 --")
        precondition(injection.isEmpty)
        let package = try await repo.exportPersonalLibraryPackage(stableKey: family.trackStableKey)
        precondition(Set(package.lyricsVersions.map(\.id)) == [aID, bID, historicalID], "Export must not lose versions hidden by grouping")
        try await repo.setPersonalLibraryActiveLyrics(trackStableKey: family.trackStableKey, lyricsVersionID: bID)
        let best = try await repo.loadBestStored(track: a, identity: TrackIdentity(track: a))
        precondition(best?.versionID == bID, "Selecting a sibling-key version must affect playback")
        let editable = try await repo.loadEditableVersion(versionID: bID, track: a, identity: TrackIdentity(track: a))
        precondition(editable?.record.id == bID, "Sibling-key versions must remain editable")
        let reopened = SQLiteLyricsRepository(databaseURL: url, alignmentProvenanceDirectory: root.appendingPathComponent("reopened"))
        let reopenedEntries = try await reopened.loadPersonalLibraryEntries()
        precondition(reopenedEntries.count == 6)
        let redirects = try await reopened.redirectCount()
        precondition(redirects == 1, "Read-time grouping must not write redirect migrations")
        print("Library identity/search PASS: one family row, all versions/detail/export, cross-key selection, full-content search, unrelated identity protection")
    }
}

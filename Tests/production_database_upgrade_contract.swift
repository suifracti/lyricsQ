import Foundation
import SQLite3

@main struct ProductionDatabaseUpgradeContract {
    static func sql(_ db: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw NSError(domain: "fixture", code: 1, userInfo: [NSLocalizedDescriptionKey: String(cString: sqlite3_errmsg(db))])
        }
    }
    static func scalar(_ db: OpaquePointer, _ sql: String, caller: Int = #line) -> Int {
        var statement: OpaquePointer?
        precondition(sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, sql)
        defer { sqlite3_finalize(statement) }
        precondition(sqlite3_step(statement) == SQLITE_ROW, "line \(caller) \(sql): \(String(cString: sqlite3_errmsg(db)))")
        return Int(sqlite3_column_int(statement, 0))
    }
    static func main() async throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        precondition(home.path.hasPrefix("/tmp/") || home.path.hasPrefix("/private/tmp/"), "Never run against user home")
        let path = SQLiteLyricsRepository.defaultDatabaseURL
        precondition(path.path.hasPrefix(home.path + "/"))
        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        let useExisting = CommandLine.arguments.contains("--existing")
        var db: OpaquePointer?
        precondition(sqlite3_open(path.path, &db) == SQLITE_OK)
        let handle = db!
        var reader: OpaquePointer?
        defer { if let reader { sqlite3_close(reader) } }
        if !useExisting {
            try DatabaseMigrator.migrate(handle, allowV6Migration: false)
            precondition(scalar(handle, "PRAGMA user_version") == 5)
            try sql(handle, "PRAGMA journal_mode=WAL;")
            precondition(sqlite3_open(path.path, &reader) == SQLITE_OK)
            try sql(reader!, "BEGIN; SELECT count(*) FROM tracks;")
            // Pin an older read snapshot so the new fixture remains in WAL.
            try sql(handle, """
                INSERT INTO tracks(stable_key,title,artist_display,album,created_at,updated_at) VALUES ('fixture','Fixture','Artist','Album',1,1);
                INSERT INTO lyrics_versions(id,track_stable_key,source,raw_text,content_hash,created_at,updated_at,confidence,language,is_manually_edited,is_locked)
                  VALUES ('11111111-1111-1111-1111-111111111111','fixture','manual','歌','fixture-hash',1,1,1,'ja',1,1);
                INSERT INTO lyric_lines(lyrics_version_id,line_index,original_text,kana_text,romaji_text)
                  VALUES ('11111111-1111-1111-1111-111111111111',0,'歌','うた','uta');
                """)
        }
        let sourceVersion = scalar(handle, "PRAGMA user_version")
        sqlite3_close(handle)
        let repository = SQLiteLyricsRepository(alignmentProvenanceDirectory: home.appendingPathComponent("provenance"))
        if CommandLine.arguments.contains("--expect-failure") {
            do {
                try await repository.prepare()
                fatalError("Expected upgrade failure")
            } catch {
                if sourceVersion > DatabaseMigrator.currentVersion {
                    guard case LyricsRepositoryError.unsupportedSchema(let version) = error, version == sourceVersion else { fatalError("Wrong future-schema error: \(error)") }
                }
                print("Upgrade rejected safely: \(error)"); return
            }
        }
        try await repository.prepare()
        precondition(sqlite3_open(path.path, &db) == SQLITE_OK)
        defer { sqlite3_close(db) }
        precondition(scalar(db!, "PRAGMA user_version") == DatabaseMigrator.currentVersion, "Existing DEFAULT-PATH database must upgrade")
        let stats = try await repository.loadListeningStatistics(for: .allTime)
        let library = try await repository.loadPersonalLibraryEntries()
        if !useExisting {
            precondition(stats.sessionCount == 0)
            precondition(library.count == 1)
            precondition(scalar(db!, "SELECT count(*) FROM lyric_lines WHERE original_text='歌' AND kana_text='うた' AND romaji_text='uta'") == 1)
            precondition(scalar(db!, "SELECT count(*) FROM lyrics_versions WHERE is_locked=1 AND is_manually_edited=1") == 1)
            precondition(scalar(db!, "SELECT count(*) FROM reading_versions") == 2)
        }
        let backups = try FileManager.default.contentsOfDirectory(at: path.deletingLastPathComponent(), includingPropertiesForKeys: nil).filter { $0.lastPathComponent.contains("pre-v") }
        if sourceVersion == DatabaseMigrator.currentVersion {
            precondition(backups.isEmpty, "Current database needs no migration backup")
            print("Current database opens without upgrade PASS")
            return
        }
        precondition(backups.count == 1, "One consistent backup before upgrading: \(backups.map(\.lastPathComponent))")
        var backup: OpaquePointer?
        precondition(sqlite3_open_v2(backups[0].path, &backup, SQLITE_OPEN_READONLY, nil) == SQLITE_OK)
        precondition(scalar(backup!, "PRAGMA user_version") == sourceVersion)
        if !useExisting {
            precondition(scalar(backup!, "SELECT count(*) FROM tracks WHERE stable_key='fixture'") == 1, "Backup includes committed WAL data")
            precondition(scalar(backup!, "SELECT count(*) FROM lyric_lines") == 1)
        }
        sqlite3_close(backup)
        if let export = ProcessInfo.processInfo.environment["UPGRADE_FIXTURE_EXPORT"] {
            try FileManager.default.copyItem(at: backups[0], to: URL(fileURLWithPath: export))
        }
        let reopened = SQLiteLyricsRepository(alignmentProvenanceDirectory: home.appendingPathComponent("provenance"))
        try await reopened.prepare()
        let afterReopen = try FileManager.default.contentsOfDirectory(atPath: path.deletingLastPathComponent().path)
        precondition(afterReopen.filter { $0.contains("pre-v") }.count == 1)
        print("Production default-path upgrade PASS; library entries: \(library.count); sessions: \(stats.sessionCount)")
    }
}

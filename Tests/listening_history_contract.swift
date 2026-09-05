import Foundation
import SQLite3

@main
@MainActor
struct ListeningHistoryContract {
    static func main() async throws {
        let trackA = Track(
            title: "Track A",
            artist: "Artist A",
            album: "Album A",
            duration: 180,
            spotifyId: "history-a"
        )
        let identityA = TrackIdentity(track: trackA)
        var sessionA = ListeningHistorySession(
            track: trackA,
            identity: identityA,
            startedAt: Date(timeIntervalSince1970: 100)
        )
        sessionA.observe(at: Date(timeIntervalSince1970: 100), position: 0, isPlaying: true)
        sessionA.observe(at: Date(timeIntervalSince1970: 110), position: 10, isPlaying: true)
        sessionA.observe(at: Date(timeIntervalSince1970: 115), position: 10, isPlaying: false)
        sessionA.observe(at: Date(timeIntervalSince1970: 120), position: 10, isPlaying: true)

        precondition(sessionA.entry.observedPlaybackDuration == 15)
        precondition(sessionA.entry.completionRatio == 15.0 / 180.0)

        let trackB = Track(
            title: "Track B",
            artist: "Artist B",
            album: "Album B",
            duration: 200,
            spotifyId: "history-b"
        )
        let identityB = TrackIdentity(track: trackB)
        var sessionB = ListeningHistorySession(
            track: trackB,
            identity: identityB,
            startedAt: Date(timeIntervalSince1970: 130)
        )
        sessionB.observe(at: Date(timeIntervalSince1970: 130), position: 0, isPlaying: true)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpotifyLyricsListeningHistoryContract-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let databaseURL = root.appendingPathComponent("SpotifyLyrics.sqlite3")
        let repository = SQLiteLyricsRepository(databaseURL: databaseURL, alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
        try await repository.prepare()
        try await repository.upsertListeningHistory(sessionA.entry)
        try await repository.upsertListeningHistory(sessionA.entry)
        try await repository.upsertListeningHistory(sessionB.entry)

        let restartedRepository = SQLiteLyricsRepository(databaseURL: databaseURL, alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
        let entries = try await restartedRepository.loadListeningHistory(limit: 10)
        precondition(entries.count == 2)
        precondition(entries[0].stableKey == identityB.stableKey)
        precondition(entries[1].stableKey == identityA.stableKey)
        precondition(entries[1].observedPlaybackDuration == 15)

        var lock: OpaquePointer?
        precondition(sqlite3_open(databaseURL.path, &lock) == SQLITE_OK)
        defer { sqlite3_exec(lock, "ROLLBACK", nil, nil, nil); sqlite3_close(lock) }
        precondition(sqlite3_exec(lock, "BEGIN EXCLUSIVE", nil, nil, nil) == SQLITE_OK)
        var rejectedLockedRead = false
        do { _ = try await restartedRepository.loadListeningHistory(limit: 10) }
        catch { rejectedLockedRead = true }
        precondition(rejectedLockedRead, "Locked history must throw instead of returning an empty success")
        var rejectedStatistics = false
        do { _ = try await restartedRepository.loadListeningStatistics(for: .allTime) }
        catch { rejectedStatistics = true }
        precondition(rejectedStatistics, "Locked statistics must throw")
        precondition(sqlite3_exec(lock, "ROLLBACK", nil, nil, nil) == SQLITE_OK)
        let recovered = try await restartedRepository.loadListeningHistory(limit: 10)
        precondition(recovered.count == 2, "History retry must recover after unlock")
        let recoveredStatistics = try await restartedRepository.loadListeningStatistics(for: .allTime)
        precondition(recoveredStatistics.sessionCount == 2)
        print("listening history contract passed (lock errors and retry verified)")
    }
}

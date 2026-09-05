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
            spotifyId: "history-a",
            artworkURL: URL(string: "https://example.invalid/cover.jpg")
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

        var loop = ListeningHistorySession(track: trackA, identity: identityA, startedAt: Date(timeIntervalSince1970: 1000))
        loop.observe(at: Date(timeIntervalSince1970: 1000), position: 0, isPlaying: true)
        for second in 1...179 { loop.observe(at: Date(timeIntervalSince1970: 1000 + Double(second)), position: Double(second), isPlaying: true) }
        let firstPlayID = loop.entry.sessionID
        let finishedFirstPlay = loop.observe(at: Date(timeIntervalSince1970: 1181), position: 1, isPlaying: true)
        precondition(loop.entry.sessionID != firstPlayID, "End-to-start repeat must create a new playback record")
        precondition(finishedFirstPlay?.sessionID == firstPlayID)
        precondition(finishedFirstPlay?.startedAt == Date(timeIntervalSince1970: 1000))
        precondition(finishedFirstPlay?.lastObservedAt == Date(timeIntervalSince1970: 1180))
        precondition(finishedFirstPlay?.observedPlaybackDuration == 180)
        precondition(loop.entry.startedAt == Date(timeIntervalSince1970: 1180), "Repeated play begins at the boundary, independently of its next observation")
        precondition(loop.entry.observedPlaybackDuration == 1)
        let secondPlayID = loop.entry.sessionID
        loop.observe(at: Date(timeIntervalSince1970: 1182), position: 80, isPlaying: true)
        loop.observe(at: Date(timeIntervalSince1970: 1183), position: 0, isPlaying: true)
        precondition(loop.entry.sessionID == secondPlayID, "Ordinary backward seek must not count as a repeat")

        var manual = ListeningHistorySession(track: trackA, identity: identityA, startedAt: Date(timeIntervalSince1970: 1))
        manual.observe(at: Date(timeIntervalSince1970: 1), position: 179, isPlaying: true)
        let manualID = manual.sessionID
        manual.noteExplicitSeek()
        manual.observe(at: Date(timeIntervalSince1970: 3), position: 1, isPlaying: true)
        precondition(manual.sessionID == manualID, "Explicit seek at track end must not count as repeat")

        // A delayed older snapshot must not rewind the accounting clock and
        // cause the next current observation to charge the same seconds twice.
        var ordered = ListeningHistorySession(track: trackA, identity: identityA, startedAt: Date(timeIntervalSince1970: 100))
        ordered.observe(at: Date(timeIntervalSince1970: 100), position: 0, isPlaying: true)
        ordered.observe(at: Date(timeIntervalSince1970: 110), position: 10, isPlaying: true)
        ordered.observe(at: Date(timeIntervalSince1970: 105), position: 5, isPlaying: true)
        ordered.observe(at: Date(timeIntervalSince1970: 115), position: 15, isPlaying: true)
        precondition(ordered.entry.observedPlaybackDuration == 15, "Older observations must not double-count elapsed playback")
        precondition(ordered.entry.startedAt == Date(timeIntervalSince1970: 100), "Play timestamp must stay fixed as playback advances")
        ordered.observe(at: Date(timeIntervalSince1970: 115), position: 15, isPlaying: false)
        ordered.observe(at: Date(timeIntervalSince1970: 200), position: 15, isPlaying: true)
        ordered.observe(at: Date(timeIntervalSince1970: 205), position: 20, isPlaying: true)
        precondition(ordered.entry.observedPlaybackDuration == 20, "Pause and resume must exclude paused wall time")

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
        precondition(entries[1].artworkURL == trackA.artworkURL, "History cover must survive reload")
        let artStats = try await restartedRepository.loadListeningStatistics(for: .allTime)
        precondition(artStats.topSongs.first(where: { $0.stableKey == identityA.stableKey })?.artworkURL == trackA.artworkURL)

        let lateTrack = Track(title: "Late artwork", artist: "Artist", album: "Album", duration: 180)
        var lateSession = ListeningHistorySession(track: lateTrack, identity: TrackIdentity(track: lateTrack))
        precondition(lateSession.entry.artworkURL == nil)
        lateSession.updateArtwork(trackA.artworkURL)
        lateSession.updateArtwork(nil)
        precondition(lateSession.entry.artworkURL == trackA.artworkURL, "Late cover must enrich session and survive nil observations")
        try await repository.upsertListeningHistory(lateSession.entry)
        let lateReload = try await repository.loadListeningHistory(limit: 10)
        precondition(lateReload.first(where: { $0.sessionID == lateSession.sessionID })?.artworkURL == trackA.artworkURL)

        let loopRepository = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("loops.sqlite3"), alignmentProvenanceDirectory: root.appendingPathComponent("loop-provenance"))
        var repeated = ListeningHistorySession(track: trackA, identity: identityA, startedAt: Date(timeIntervalSince1970: 2000))
        for second in 0...1081 {
            if let finished = repeated.observe(at: Date(timeIntervalSince1970: 2000 + Double(second)), position: Double(second % 180), isPlaying: true) {
                try await loopRepository.upsertListeningHistory(finished)
            }
        }
        try await loopRepository.upsertListeningHistory(repeated.entry)
        let repeatedRows = try await loopRepository.loadListeningHistory(limit: 10)
        precondition(repeatedRows.count == 7, "Repeated song occurrences must remain separate history rows")
        precondition(Set(repeatedRows.map(\.sessionID)).count == 7)
        precondition(repeatedRows.map(\.startedAt) == [3080.0, 2900, 2720, 2540, 2360, 2180, 2000].map(Date.init(timeIntervalSince1970:)))
        precondition(repeatedRows.map(\.observedPlaybackDuration) == [1, 180, 180, 180, 180, 180, 180], "Each persisted row must carry only its own listening time")
        let loopStats = try await loopRepository.loadListeningStatistics(for: .allTime)
        precondition(loopStats.sessionCount == 7, "Six full repeats plus current play must remain seven records")
        precondition(loopStats.totalListeningTime == 1081, "Repeat split must neither lose nor duplicate elapsed time")
        var paused = ListeningHistorySession(track: trackA, identity: identityA, startedAt: Date(timeIntervalSince1970: 1))
        paused.observe(at: Date(timeIntervalSince1970: 1), position: 179, isPlaying: false)
        let pausedID = paused.sessionID
        paused.observe(at: Date(timeIntervalSince1970: 3), position: 1, isPlaying: true)
        precondition(paused.sessionID == pausedID, "Paused seek is not an observed repeat")
        paused.observe(at: Date(timeIntervalSince1970: 4), position: 179, isPlaying: true)
        paused.observe(at: Date(timeIntervalSince1970: 100), position: 1, isPlaying: true)
        precondition(paused.sessionID == pausedID, "Unobserved long gap must not invent repeat count")

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
        precondition(recovered.count == 3, "History retry must recover after unlock")
        let recoveredStatistics = try await restartedRepository.loadListeningStatistics(for: .allTime)
        precondition(recoveredStatistics.sessionCount == 3)
        print("listening history contract passed (lock errors and retry verified)")
    }
}

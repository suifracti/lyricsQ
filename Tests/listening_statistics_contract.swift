import Foundation

@main
@MainActor
struct ListeningStatisticsContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpotifyLyricsListeningStatisticsContract-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let repository = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("SpotifyLyrics.sqlite3"))
        try await repository.prepare()

        try await repository.upsertListeningHistory(entry(
            id: "A1", key: "spotify-id:history-a", title: "Song A", artist: "Artist X", duration: 60, observedAt: 100
        ))
        try await repository.upsertListeningHistory(entry(
            id: "A2", key: "spotify-id:history-a", title: "Song A", artist: "Artist X", duration: 40, observedAt: 110
        ))
        try await repository.upsertListeningHistory(entry(
            id: "B1", key: "spotify-id:history-b", title: "Song B", artist: "Artist X", duration: 80, observedAt: 120
        ))
        try await repository.upsertListeningHistory(entry(
            id: "Y1", key: "spotify-id:history-y", title: "Song Y", artist: "Artist Y", duration: 80, observedAt: 130
        ))

        let statistics = try await repository.loadListeningStatistics(for: .allTime)
        precondition(statistics.totalListeningTime == 260)
        precondition(statistics.sessionCount == 4)
        precondition(statistics.uniqueSongCount == 3)
        precondition(statistics.dailyPlayCounts.count == 7)
        precondition(statistics.dailyPlayCounts.map(\.count) == [0, 0, 0, 0, 0, 0, 0])
        precondition(statistics.topSongs.map(\.stableKey) == [
            "spotify-id:history-a",
            "spotify-id:history-b",
            "spotify-id:history-y"
        ])
        precondition(statistics.topSongs.map(\.sessionCount) == [2, 1, 1])
        precondition(statistics.topSongs.map(\.observedListeningTime) == [100, 80, 80])
        precondition(statistics.topArtists.map(\.artist) == ["Artist X", "Artist Y"])
        precondition(statistics.topArtists.map(\.sessionCount) == [3, 1])
        precondition(statistics.topArtists.map(\.observedListeningTime) == [180, 80])

        let now = Date().timeIntervalSince1970
        try await repository.upsertListeningHistory(ListeningHistoryEntry(
            sessionID: UUID(),
            stableKey: "spotify-id:today-1",
            title: "Song Today",
            artist: "Artist Today",
            album: "Album",
            startedAt: Date(timeIntervalSince1970: now - 60),
            lastObservedAt: Date(timeIntervalSince1970: now),
            observedPlaybackDuration: 60,
            trackDuration: 180,
            completionRatio: 60.0 / 180.0
        ))
        let updatedStats = try await repository.loadListeningStatistics(for: .allTime)
        precondition(updatedStats.sessionCount == 5)
        precondition(updatedStats.uniqueSongCount == 4)
        precondition(updatedStats.dailyPlayCounts.count == 7)
        precondition(updatedStats.dailyPlayCounts.last?.count == 1)
        precondition(updatedStats.dailyPlayCounts.dropLast().allSatisfy { $0.count == 0 })

        let emptyRepository = SQLiteLyricsRepository(
            databaseURL: root.appendingPathComponent("empty.sqlite3")
        )
        let emptyStatistics = try await emptyRepository.loadListeningStatistics(for: .allTime)
        precondition(emptyStatistics.isEmpty)
        precondition(emptyStatistics.sessionCount == 0)
        precondition(emptyStatistics.uniqueSongCount == 0)
        precondition(emptyStatistics.dailyPlayCounts.count == 7)
        precondition(emptyStatistics.dailyPlayCounts.allSatisfy { $0.count == 0 })

        print("listening statistics contract passed")
    }

    private static func entry(
        id: String,
        key: String,
        title: String,
        artist: String,
        duration: TimeInterval,
        observedAt: TimeInterval
    ) -> ListeningHistoryEntry {
        ListeningHistoryEntry(
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-00000000\(id == "A1" ? "0011" : id == "A2" ? "0022" : id == "B1" ? "0033" : "0044")")!,
            stableKey: key,
            title: title,
            artist: artist,
            album: "Album",
            startedAt: Date(timeIntervalSince1970: observedAt - duration),
            lastObservedAt: Date(timeIntervalSince1970: observedAt),
            observedPlaybackDuration: duration,
            trackDuration: 180,
            completionRatio: duration / 180
        )
    }
}

import Foundation
import SQLite3
@main @MainActor struct ReliabilityPlaybackContract {
 static func main() async throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("lyrics-playback-reliability-\(UUID())")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }
  print("Isolated database: \(root.path)")
  let url = root.appendingPathComponent("test.sqlite3")
  let repository = SQLiteLyricsRepository(databaseURL: url, alignmentProvenanceDirectory: root.appendingPathComponent("provenance"))
  try await repository.prepare()
  let state = PlaybackSlice(repository: repository)
  let a = Track(title: "Live A", artist: "Artist", album: "", duration: 180, spotifyId: "live-a")
  let b = Track(title: "Preview B", artist: "Artist", album: "", duration: 180, spotifyId: "preview-b")
  state.lyricsSession.begin(track: a, identity: TrackIdentity(track: a), automaticallySearch: false)
  state.searchPreviewSession.begin(track: b, identity: TrackIdentity(track: b), automaticallySearch: false)
  state.searchPreviewTrack = b
  func candidate(_ track: Track) -> LyricsCandidate {
   LyricsCandidate(id: track.title, identity: TrackIdentity(track: track), title: track.title, artist: track.artist, album: "", duration: 180, lines: [LyricLine(timestamp: 0, originalText: track.title)], source: .lrclib, confidence: 1)
  }
  state.adoptLyricsCandidate(candidate(b))
  precondition(state.searchPreviewSession.activeDocument?.title == b.title, "Preview candidate must be adopted into preview session")
  precondition(state.lyricsSession.activeDocument == nil, "Preview adoption must leave live session unchanged")
  state.adoptLyricsCandidate(candidate(a))
  precondition(state.searchPreviewSession.activeDocument?.title == b.title, "Cross-track candidate must still be rejected")
  state.searchPreviewTrack = nil
  state.adoptLyricsCandidate(candidate(a))
  precondition(state.lyricsSession.activeDocument?.title == a.title, "Live adoption must remain functional")
  let entry = ListeningHistoryEntry(sessionID: UUID(), stableKey: "live-a", title: "Live A", artist: "Artist", album: "", startedAt: Date(), lastObservedAt: Date(), observedPlaybackDuration: 60, trackDuration: 180, completionRatio: 1/3)
  try await repository.upsertListeningHistory(entry)
  state.refreshListeningHistory(); precondition(state.isListeningHistoryLoading); await state.listeningHistoryLoadTask?.value
  state.refreshListeningStatistics(for: .allTime); await state.listeningStatisticsLoadTask?.value
  precondition(state.listeningHistory.count == 1)
  precondition(state.listeningStatistics?.sessionCount == 1)
  var lock: OpaquePointer?
  precondition(sqlite3_open(url.path, &lock) == SQLITE_OK)
  defer { sqlite3_exec(lock, "ROLLBACK", nil, nil, nil); sqlite3_close(lock) }
  precondition(sqlite3_exec(lock, "BEGIN EXCLUSIVE", nil, nil, nil) == SQLITE_OK)
  state.refreshListeningHistory(); await state.listeningHistoryLoadTask?.value
  state.refreshListeningStatistics(for: .allTime); await state.listeningStatisticsLoadTask?.value
  precondition(state.listeningHistory.count == 1, "History failure must retain last good entries")
  precondition(state.listeningStatistics?.sessionCount == 1, "Statistics failure must retain last good result")
  precondition(state.listeningHistoryError != nil && state.listeningStatisticsError != nil, "Failures must be observable, not empty success")
  precondition(!state.isListeningHistoryLoading && !state.isListeningStatisticsLoading)
  state.refreshListeningStatistics(for: .last7Days); await state.listeningStatisticsLoadTask?.value
  precondition(state.listeningStatistics?.timeRange == .allTime, "Failed range switch retains accurately labelled last result")
  let cold = PlaybackSlice(repository: repository)
  cold.refreshListeningHistory(); await cold.listeningHistoryLoadTask?.value
  cold.refreshListeningStatistics(for: .allTime); await cold.listeningStatisticsLoadTask?.value
  precondition(cold.listeningHistory.isEmpty && cold.listeningHistoryError != nil)
  precondition(cold.listeningStatistics == nil && cold.listeningStatisticsError != nil, "Cold failures must not become empty statistics")
  precondition(sqlite3_exec(lock, "ROLLBACK", nil, nil, nil) == SQLITE_OK)
  state.refreshListeningHistory(); await state.listeningHistoryLoadTask?.value
  state.refreshListeningStatistics(for: .allTime); await state.listeningStatisticsLoadTask?.value
  precondition(state.listeningHistoryError == nil && state.listeningStatisticsError == nil, "Successful retry clears failure")
  precondition(state.listeningHistory.count == 1 && state.listeningStatistics?.sessionCount == 1)
  print("PASS preview/live routing, identity protection, real SQLite load failure, retained content and retry")
 }
}

import Foundation

/// One continuous playback session observed by Lyric Island.
///
/// This is intentionally separate from Spotify's account history: it only
/// describes playback snapshots seen while this app was running.
public struct ListeningHistoryEntry: Identifiable, Equatable, Hashable, Sendable {
    public let sessionID: UUID
    public let stableKey: String
    public let title: String
    public let artist: String
    public let album: String
    public let startedAt: Date
    public let lastObservedAt: Date
    public let observedPlaybackDuration: TimeInterval
    public let trackDuration: TimeInterval?
    public let completionRatio: Double?

    public var id: UUID { sessionID }

    public init(
        sessionID: UUID,
        stableKey: String,
        title: String,
        artist: String,
        album: String,
        startedAt: Date,
        lastObservedAt: Date,
        observedPlaybackDuration: TimeInterval,
        trackDuration: TimeInterval?,
        completionRatio: Double?
    ) {
        self.sessionID = sessionID
        self.stableKey = stableKey
        self.title = title
        self.artist = artist
        self.album = album
        self.startedAt = startedAt
        self.lastObservedAt = lastObservedAt
        self.observedPlaybackDuration = max(0, observedPlaybackDuration)
        self.trackDuration = trackDuration
        self.completionRatio = completionRatio
    }
}

/// Main-actor-owned accumulator for one stable track identity.
///
/// Repeated observations update this value; they do not create another
/// session. Paused time is excluded because the accumulator only adds time
/// between observations when the previous snapshot was playing.
public struct ListeningHistorySession: Sendable {
    private static let maximumObservationGap: TimeInterval = 10

    public let sessionID: UUID
    public let stableKey: String
    public let title: String
    public let artist: String
    public let album: String
    public let startedAt: Date
    public let trackDuration: TimeInterval?

    private var lastObservationAt: Date
    private var wasPlaying = false
    private var observedPlaybackDuration: TimeInterval = 0

    public init(
        track: Track,
        identity: TrackIdentity,
        startedAt: Date = Date(),
        sessionID: UUID = UUID()
    ) {
        self.sessionID = sessionID
        self.stableKey = identity.stableKey
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.startedAt = startedAt
        self.trackDuration = Self.normalizedDuration(track.duration)
        self.lastObservationAt = startedAt
    }

    public mutating func observe(at date: Date, position: TimeInterval, isPlaying: Bool) {
        let elapsed = date.timeIntervalSince(lastObservationAt)
        if wasPlaying, elapsed.isFinite, elapsed > 0 {
            observedPlaybackDuration += min(elapsed, Self.maximumObservationGap)
        }
        lastObservationAt = date
        wasPlaying = isPlaying
    }

    public var entry: ListeningHistoryEntry {
        let ratio: Double?
        if let duration = trackDuration, duration > 0 {
            ratio = min(1, observedPlaybackDuration / duration)
        } else {
            ratio = nil
        }
        return ListeningHistoryEntry(
            sessionID: sessionID,
            stableKey: stableKey,
            title: title,
            artist: artist,
            album: album,
            startedAt: startedAt,
            lastObservedAt: lastObservationAt,
            observedPlaybackDuration: observedPlaybackDuration,
            trackDuration: trackDuration,
            completionRatio: ratio
        )
    }

    private static func normalizedDuration(_ duration: TimeInterval) -> TimeInterval? {
        guard duration.isFinite, duration > 0 else { return nil }
        return duration
    }
}

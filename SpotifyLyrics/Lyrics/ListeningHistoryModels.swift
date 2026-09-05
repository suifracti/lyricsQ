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
    public var artworkURL: URL?

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
        completionRatio: Double?,
        artworkURL: URL? = nil
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
        self.artworkURL = artworkURL
    }
}

/// Main-actor-owned accumulator for one stable track identity.
///
/// Repeated observations update this value; they do not create another
/// session unless an observed end-to-start repeat occurs. Paused time is excluded because the accumulator only adds time
/// between observations when the previous snapshot was playing.
public struct ListeningHistorySession: Sendable {
    private static let maximumObservationGap: TimeInterval = 10

    public private(set) var sessionID: UUID
    public let stableKey: String
    public let title: String
    public let artist: String
    public let album: String
    public private(set) var startedAt: Date
    public let trackDuration: TimeInterval?

    private var lastObservationAt: Date
    private var lastPosition: TimeInterval?
    private var artworkURL: URL?
    private var wasPlaying = false
    private var observedPlaybackDuration: TimeInterval = 0

    public init(
        track: Track,
        identity: TrackIdentity,
        startedAt: Date = Date(),
        sessionID: UUID = UUID()
    ) {
        self.artworkURL = track.artworkURL
        self.sessionID = sessionID
        self.stableKey = identity.stableKey
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.startedAt = startedAt
        self.trackDuration = Self.normalizedDuration(track.duration)
        self.lastObservationAt = startedAt
    }

    public mutating func updateArtwork(_ url: URL?) {
        if let url { artworkURL = url }
    }

    public mutating func noteExplicitSeek() { lastPosition = nil }

    /// Returns the completed play when a sampled end-to-start boundary is observed.
    @discardableResult
    public mutating func observe(at date: Date, position: TimeInterval, isPlaying: Bool) -> ListeningHistoryEntry? {
        let elapsed = date.timeIntervalSince(lastObservationAt)
        var completed: ListeningHistoryEntry?
        if wasPlaying, isPlaying, let previous = lastPosition, let duration = trackDuration,
           elapsed > 0, elapsed <= Self.maximumObservationGap,
           previous >= max(duration * 0.9, duration - Self.maximumObservationGap),
           position >= 0, position <= elapsed + 2, previous - position > duration * 0.5,
           abs((duration - previous + position) - elapsed) <= 2 {
            let tail = min(elapsed, max(0, duration - previous))
            observedPlaybackDuration += tail
            lastObservationAt = date.addingTimeInterval(-(elapsed - tail))
            completed = entry
            sessionID = UUID()
            startedAt = lastObservationAt
            observedPlaybackDuration = elapsed - tail
        }
        if completed == nil, wasPlaying, elapsed.isFinite, elapsed > 0 {
            observedPlaybackDuration += min(elapsed, Self.maximumObservationGap)
        }
        lastObservationAt = date
        wasPlaying = isPlaying
        lastPosition = position.isFinite ? position : nil
        return completed
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
            completionRatio: ratio,
            artworkURL: artworkURL
        )
    }

    private static func normalizedDuration(_ duration: TimeInterval) -> TimeInterval? {
        guard duration.isFinite, duration > 0 else { return nil }
        return duration
    }
}

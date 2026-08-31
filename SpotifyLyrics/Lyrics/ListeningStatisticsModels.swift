import Foundation

/// Time windows supported by the local observed-playback statistics.
public enum ListeningStatisticsTimeRange: String, CaseIterable, Identifiable, Equatable, Sendable {
    case last7Days
    case last30Days
    case allTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .last7Days: return "最近 7 天"
        case .last30Days: return "最近 30 天"
        case .allTime: return "全部时间"
        }
    }

    /// Statistics use `last_observed_at` as the session's time-range anchor.
    public var lowerBound: Date {
        switch self {
        case .last7Days:
            return Date().addingTimeInterval(-7 * 24 * 60 * 60)
        case .last30Days:
            return Date().addingTimeInterval(-30 * 24 * 60 * 60)
        case .allTime:
            return Date(timeIntervalSince1970: 0)
        }
    }
}

public struct ListeningStatisticsSong: Identifiable, Equatable, Sendable {
    public let stableKey: String
    public let title: String
    public let artist: String
    public let observedListeningTime: TimeInterval
    public let sessionCount: Int

    public var id: String { stableKey }
}

public struct ListeningStatisticsArtist: Identifiable, Equatable, Sendable {
    public let artist: String
    public let observedListeningTime: TimeInterval
    public let sessionCount: Int

    public var id: String { artist }
}

public struct ListeningStatistics: Equatable, Sendable {
    public let timeRange: ListeningStatisticsTimeRange
    public let totalListeningTime: TimeInterval
    public let sessionCount: Int
    public let topSongs: [ListeningStatisticsSong]
    public let topArtists: [ListeningStatisticsArtist]

    public var isEmpty: Bool { sessionCount == 0 }

    public static func empty(for timeRange: ListeningStatisticsTimeRange) -> ListeningStatistics {
        ListeningStatistics(
            timeRange: timeRange,
            totalListeningTime: 0,
            sessionCount: 0,
            topSongs: [],
            topArtists: []
        )
    }
}

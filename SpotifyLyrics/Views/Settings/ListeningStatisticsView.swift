import SwiftUI

public struct ListeningStatisticsView: View {
    @EnvironmentObject private var playback: PlaybackState
    @State private var selectedTimeRange: ListeningStatisticsTimeRange = .allTime

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("听歌统计")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text("仅统计 Lyric Island 运行期间实际观察到的播放，不代表 Spotify 完整历史。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(ListeningStatisticsTimeRange.allCases) { timeRange in
                        Text(timeRange.title).tag(timeRange)
                    }
                }
                .pickerStyle(.segmented)

                if let statistics = playback.listeningStatistics,
                   statistics.timeRange == selectedTimeRange {
                    if statistics.isEmpty {
                        emptyState
                    } else {
                        summary(statistics)
                        topSongs(statistics.topSongs)
                        topArtists(statistics.topArtists)
                    }
                } else {
                    ProgressView("读取统计…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
        }
        .padding(28)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    playback.refreshListeningStatistics(for: selectedTimeRange)
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .help("刷新听歌统计")
            }
        }
        .onAppear {
            playback.refreshListeningStatistics(for: selectedTimeRange)
        }
        .onChange(of: selectedTimeRange) { _, newValue in
            playback.refreshListeningStatistics(for: newValue)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text("暂无统计记录")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("播放歌曲后，这里会显示 Lyric Island 观察到的听歌时长和排序。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func summary(_ statistics: ListeningStatistics) -> some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "总听歌时长",
                value: formattedDuration(statistics.totalListeningTime),
                icon: "clock"
            )
            summaryCard(
                title: "观察 session 数",
                value: "\(statistics.sessionCount)",
                icon: "music.note.list"
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func topSongs(_ songs: [ListeningStatisticsSong]) -> some View {
        statisticsGroup(title: "Top Songs", icon: "music.note") {
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 22, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(formattedDuration(song.observedListeningTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                if song.id != songs.last?.id {
                    Divider()
                }
            }
        }
    }

    private func topArtists(_ artists: [ListeningStatisticsArtist]) -> some View {
        statisticsGroup(title: "Top Artists", icon: "person.2") {
            ForEach(Array(artists.enumerated()), id: \.element.id) { index, artist in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 22, alignment: .leading)
                    Text(artist.artist)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(formattedDuration(artist.observedListeningTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                if artist.id != artists.last?.id {
                    Divider()
                }
            }
        }
    }

    private func statisticsGroup<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            VStack(spacing: 8) {
                content()
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(hours)小时 \(minutes)分"
        }
        if minutes > 0 {
            return "\(minutes)分 \(seconds)秒"
        }
        return "\(seconds)秒"
    }
}

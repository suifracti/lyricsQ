import SwiftUI

public struct ListeningHistoryView: View {
    @EnvironmentObject private var playback: PlaybackState

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("最近播放")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Text("仅记录 Lyric Island 运行期间实际观察到的歌曲，不代表 Spotify 完整播放历史。")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 10)

            if playback.listeningHistory.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 34))
                        .foregroundStyle(.tertiary)
                    Text("暂无 Lyric Island 观察记录")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("播放歌曲后，这里会显示本次运行期间观察到的记录。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(playback.listeningHistory) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.secondary)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text(entry.artist)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 12)

                        Text(entry.lastObservedAt, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .padding(28)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    playback.refreshListeningHistory()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .help("刷新最近播放记录")
            }
        }
        .onAppear {
            playback.refreshListeningHistory()
        }
    }
}

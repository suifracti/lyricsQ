import SwiftUI

public struct MenuBarLyricsPopoverView: View {
    @ObservedObject var controller: MenuBarLyricsController

    public init(controller: MenuBarLyricsController) {
        self.controller = controller
    }

    public var body: some View {
        let snapshot = controller.currentSnapshot
        VStack(alignment: .leading, spacing: 12) {
            // Header: Track title & Artist
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.trackTitle ?? "未在播放歌曲")
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Text(snapshot.artistName ?? "Spotify")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            Divider()

            // Lyrics display area
            VStack(alignment: .leading, spacing: 6) {
                switch snapshot.state {
                case .idle:
                    Text("暂无播放中的曲目")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)

                case .loading:
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("正在加载歌词…")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                case .synchronized(let current, let next):
                    if current.isEmpty && (next == nil || next?.isEmpty == true) {
                        Text("♪ (前奏 / 间奏)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        if !current.isEmpty {
                            Text(current)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let next, !next.isEmpty {
                            Text(next)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                case .unsynchronized:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("歌词尚未同步")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("可在主窗口或编辑器中查看与排轴")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)

                case .noLyrics:
                    Text("未找到歌词")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)

                case .failed:
                    Text("歌词加载失败")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
            .frame(minHeight: 44)

            Divider()

            // Bottom Controls & Open Main Window
            HStack(alignment: .center, spacing: 14) {
                Button(action: {
                    controller.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(!snapshot.hasLiveTrack)

                Button(action: {
                    controller.togglePlayPause()
                }) {
                    Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(!snapshot.hasLiveTrack)

                Button(action: {
                    controller.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(!snapshot.hasLiveTrack)

                Spacer()

                Button("打开主窗口") {
                    controller.openMainWindow()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 290)
    }
}

import AppKit
import Combine
import SwiftUI

public enum MenuBarLyricsState: Equatable, Sendable {
    case idle
    case loading(title: String)
    case synchronized(current: String, next: String?)
    case unsynchronized(title: String)
    case noLyrics(title: String)
    case failed(title: String)
}

public struct MenuBarLyricsSnapshot: Equatable, Sendable {
    public let state: MenuBarLyricsState
    public let statusText: String
    public let trackTitle: String?
    public let artistName: String?
    public let currentLineText: String?
    public let nextLineText: String?
    public let isPlaying: Bool
    public let hasLiveTrack: Bool
}

public enum MenuBarTextFormatter {
    public static let maxVisualWidth: CGFloat = 240.0
    public static let font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))

    public static func truncateToFit(_ text: String, maxWidth: CGFloat = maxVisualWidth, font: NSFont = font) -> String {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let baseSize = (text as NSString).size(withAttributes: attributes)
        if baseSize.width <= maxWidth {
            return text
        }

        let ellipsis = "…"
        var low = 0
        var high = text.count
        var best = ellipsis

        while low <= high {
            let mid = (low + high) / 2
            let prefixIndex = text.index(text.startIndex, offsetBy: mid)
            let candidate = String(text[..<prefixIndex]) + ellipsis
            let candidateSize = (candidate as NSString).size(withAttributes: attributes)

            if candidateSize.width <= maxWidth {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return best
    }
}

@MainActor
public final class MenuBarLyricsController: NSObject, ObservableObject {
    public static let shared = MenuBarLyricsController()

    @Published public private(set) var currentSnapshot: MenuBarLyricsSnapshot

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var playbackState: PlaybackState?
    private var cancellables = Set<AnyCancellable>()
    private var openMainWindowHandler: (@MainActor () -> Void)?

    private override init() {
        self.currentSnapshot = MenuBarLyricsSnapshot(
            state: .idle,
            statusText: "Lyric Island",
            trackTitle: nil,
            artistName: nil,
            currentLineText: nil,
            nextLineText: nil,
            isPlaying: false,
            hasLiveTrack: false
        )
        super.init()
    }

    public func bind(playbackState: PlaybackState) {
        self.playbackState = playbackState
        cancellables.removeAll()

        setupStatusItemIfNeeded()
        setupPopoverIfNeeded()

        playbackState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackStateChange()
            }
            .store(in: &cancellables)

        handlePlaybackStateChange()
    }

    public func setOpenMainWindowHandler(_ handler: @escaping @MainActor () -> Void) {
        self.openMainWindowHandler = handler
    }

    public func openMainWindow() {
        popover?.performClose(nil)

        openMainWindowHandler?()

        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main-window" || window.title == "Lyric Island" {
                if !window.isKind(of: NSPanel.self) {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }

    public func togglePlayPause() {
        playbackState?.togglePlayPause()
    }

    public func previousTrack() {
        playbackState?.previousTrack()
    }

    public func nextTrack() {
        playbackState?.nextTrack()
    }

    private func setupStatusItemIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeft
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Lyric Island")
            button.title = "Lyric Island"
        }
        self.statusItem = item
    }

    private func setupPopoverIfNeeded() {
        guard popover == nil else { return }
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: MenuBarLyricsPopoverView(controller: self)
        )
        self.popover = pop
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func handlePlaybackStateChange() {
        guard let playbackState else { return }
        let newSnapshot = Self.deriveSnapshot(from: playbackState)

        guard newSnapshot != currentSnapshot else { return }

        let oldSnapshot = currentSnapshot
        currentSnapshot = newSnapshot

        updateStatusItemButton(newSnapshot: newSnapshot, oldSnapshot: oldSnapshot)
    }

    private func updateStatusItemButton(newSnapshot: MenuBarLyricsSnapshot, oldSnapshot: MenuBarLyricsSnapshot) {
        guard let button = statusItem?.button else { return }

        let truncatedTitle = MenuBarTextFormatter.truncateToFit(newSnapshot.statusText)
        button.title = truncatedTitle

        if newSnapshot.hasLiveTrack {
            button.image = NSImage(
                systemSymbolName: newSnapshot.isPlaying ? "music.note" : "pause.fill",
                accessibilityDescription: "Lyric Island"
            )
        } else {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Lyric Island")
        }
    }

    public static func deriveSnapshot(from state: PlaybackState) -> MenuBarLyricsSnapshot {
        guard state.hasLiveTrack, !state.isMockPreviewMode else {
            return MenuBarLyricsSnapshot(
                state: .idle,
                statusText: "Lyric Island",
                trackTitle: nil,
                artistName: nil,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: false,
                hasLiveTrack: false
            )
        }

        let track = state.currentTrack
        let title = track.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = track.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaying = state.isPlaying

        guard state.liveLyricsDocumentMatchesCurrentTrack else {
            let displayTitle = title.isEmpty ? "Lyric Island" : title
            return MenuBarLyricsSnapshot(
                state: .loading(title: displayTitle),
                statusText: "♪ \(displayTitle)",
                trackTitle: displayTitle,
                artistName: artist,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: isPlaying,
                hasLiveTrack: true
            )
        }

        let lyricsLoadState = state.liveLyricsState
        switch lyricsLoadState {
        case .loading:
            let displayTitle = title.isEmpty ? "Lyric Island" : title
            return MenuBarLyricsSnapshot(
                state: .loading(title: displayTitle),
                statusText: "♪ \(displayTitle)",
                trackTitle: displayTitle,
                artistName: artist,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: isPlaying,
                hasLiveTrack: true
            )

        case .noLyrics, .noSelection, .noMatch:
            let displayTitle = title.isEmpty ? "Lyric Island" : title
            return MenuBarLyricsSnapshot(
                state: .noLyrics(title: displayTitle),
                statusText: "♪ \(displayTitle)",
                trackTitle: displayTitle,
                artistName: artist,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: isPlaying,
                hasLiveTrack: true
            )

        case .failed:
            let displayTitle = title.isEmpty ? "Lyric Island" : title
            return MenuBarLyricsSnapshot(
                state: .failed(title: displayTitle),
                statusText: "♪ \(displayTitle)",
                trackTitle: displayTitle,
                artistName: artist,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: isPlaying,
                hasLiveTrack: true
            )

        case .loaded, .alignmentQueued, .alignmentRunning, .alignmentPreview:
            let lines = state.liveLyrics
            let isSync = state.liveLyricsAreSynchronized

            if isSync, let currentIndex = state.liveCurrentLineIndex, currentIndex >= 0, currentIndex < lines.count {
                let currentLine = lines[currentIndex].originalText.trimmingCharacters(in: .whitespacesAndNewlines)
                let nextLine: String? = (currentIndex + 1 < lines.count)
                    ? lines[currentIndex + 1].originalText.trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil

                let statusText = currentLine.isEmpty ? "♪ \(title)" : "♪ \(currentLine)"
                return MenuBarLyricsSnapshot(
                    state: .synchronized(current: currentLine, next: nextLine),
                    statusText: statusText,
                    trackTitle: title,
                    artistName: artist,
                    currentLineText: currentLine,
                    nextLineText: nextLine,
                    isPlaying: isPlaying,
                    hasLiveTrack: true
                )
            } else if !isSync {
                let displayTitle = title.isEmpty ? "Lyric Island" : title
                return MenuBarLyricsSnapshot(
                    state: .unsynchronized(title: displayTitle),
                    statusText: "♪ \(displayTitle)",
                    trackTitle: displayTitle,
                    artistName: artist,
                    currentLineText: nil,
                    nextLineText: nil,
                    isPlaying: isPlaying,
                    hasLiveTrack: true
                )
            } else {
                let displayTitle = title.isEmpty ? "Lyric Island" : title
                let nextLine: String? = lines.first?.originalText.trimmingCharacters(in: .whitespacesAndNewlines)
                return MenuBarLyricsSnapshot(
                    state: .synchronized(current: "", next: nextLine),
                    statusText: "♪ \(displayTitle)",
                    trackTitle: displayTitle,
                    artistName: artist,
                    currentLineText: nil,
                    nextLineText: nextLine,
                    isPlaying: isPlaying,
                    hasLiveTrack: true
                )
            }

        case .idle, .candidates, .mockPreview:
            let displayTitle = title.isEmpty ? "Lyric Island" : title
            return MenuBarLyricsSnapshot(
                state: .noLyrics(title: displayTitle),
                statusText: "♪ \(displayTitle)",
                trackTitle: displayTitle,
                artistName: artist,
                currentLineText: nil,
                nextLineText: nil,
                isPlaying: isPlaying,
                hasLiveTrack: true
            )
        }
    }
}

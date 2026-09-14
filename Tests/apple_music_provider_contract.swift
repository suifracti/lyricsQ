import Foundation

@main
@MainActor
struct AppleMusicProviderContract {
    static func main() async {
        let separator = String(UnicodeScalar(30))

        // 1. Test AppleMusicDesktopProvider with mock script runner
        let provider = AppleMusicDesktopProvider { script, timeout in
            if script.contains("current track") {
                precondition(timeout == 3)
                return [
                    "playing", "45.2", "七里香", "周杰伦", "七里香", "299.0",
                    "3B1F8E109761A672", "0"
                ].joined(separator: separator)
            }
            precondition(timeout == 5)
            return ""
        }

        let snapshot = await provider.refresh()
        precondition(snapshot.status == .ready, "Status should be ready")
        precondition(snapshot.track?.title == "七里香", "Title mismatch")
        precondition(snapshot.track?.artist == "周杰伦", "Artist mismatch")
        precondition(snapshot.track?.album == "七里香", "Album mismatch")
        precondition(snapshot.track?.duration == 299.0, "Duration mismatch")
        precondition(snapshot.track?.id == "applemusic:3B1F8E109761A672", "Track ID mismatch")
        precondition(snapshot.isPlaying == true, "isPlaying mismatch")
        precondition(snapshot.position == 45.2, "Position mismatch")

        // 2. Test stopped with no track
        let emptyProvider = AppleMusicDesktopProvider { script, _ in
            return [
                "stopped", "0", "", "", "", "0", "", "0"
            ].joined(separator: separator)
        }
        let emptySnapshot = await emptyProvider.refresh()
        precondition(emptySnapshot.status == .noTrack, "Empty state should be .noTrack")
        precondition(emptySnapshot.track == nil, "Empty track should be nil")
        precondition(!emptySnapshot.isPlaying, "Empty track should not be playing")

        // 3. Test PlaybackProviderState userFacingMessage
        let state = PlaybackProviderState.ready
        precondition(state.userFacingMessage(for: "Apple Music") == "Apple Music 已连接")
        let notRunningState = PlaybackProviderState.notRunning
        precondition(notRunningState.userFacingMessage(for: "Apple Music") == "Apple Music 未运行")

        print("Apple Music provider contract passed")
    }
}

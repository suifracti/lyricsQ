import AppKit

@main
struct TrackMetadataCopyContract {
    static func main() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SpotifyLyrics.TrackMetadataCopy.Contract"))

        precondition(
            TrackMetadataCopy.copy("アーカイブ - Piano Ver.", to: pasteboard),
            "copying the title should write to the pasteboard"
        )
        precondition(
            pasteboard.string(forType: .string) == "アーカイブ - Piano Ver.",
            "the copied title must remain unchanged"
        )

        precondition(
            TrackMetadataCopy.copy("stb", to: pasteboard),
            "copying the artist should write to the pasteboard"
        )
        precondition(
            pasteboard.string(forType: .string) == "stb",
            "the artist copy should replace the previous title"
        )
    }
}

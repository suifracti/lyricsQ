import Foundation

@main
struct LyricsVersionSwitchContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpotifyLyricsVersionSwitch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let track = Track(
            id: "version-switch-track",
            title: "版本切换测试",
            artist: "Lyric Island",
            album: "Single",
            duration: 180,
            spotifyId: "version-switch-track"
        )
        let identity = TrackIdentity(track: track)
        let repository = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("lyrics.sqlite3"))
        try await repository.prepare()

        let original = LyricsDocument(
            identity: identity,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            lines: [
                LyricLine(timestamp: 0, originalText: "原始版本")
            ],
            isSynchronized: true,
            source: .lrclib,
            confidence: 1,
            providerSourceID: "provider-original"
        )
        let savedOriginal = try await repository.save(track: track, identity: identity, document: original)
        guard let originalID = savedOriginal.versionID,
              let originalHash = savedOriginal.sourceContentHash else {
            throw ContractError("original version was not persisted")
        }

        let revision = LyricsDocument(
            identity: identity,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            lines: [
                LyricLine(timestamp: 0, originalText: "修订版本")
            ],
            isSynchronized: true,
            source: .manualEdit,
            confidence: 1,
            providerSourceID: "manualEdit"
        )
        let savedRevision = try await repository.saveManualEdit(LyricsEditSaveRequest(
            track: track,
            identity: identity,
            sourceVersionID: originalID,
            sourceContentHash: originalHash,
            document: revision,
            createLyricsVersion: true
        ))
        guard let revisionID = savedRevision.lyricsVersion?.record.id else {
            throw ContractError("revision version was not persisted")
        }

        let versionsBefore = try await repository.loadEditableVersions(track: track, identity: identity)
        guard versionsBefore.contains(where: { $0.record.id == originalID }),
              versionsBefore.contains(where: { $0.record.id == revisionID }) else {
            throw ContractError("both saved versions were not visible")
        }
        guard (try await repository.loadBestStored(track: track, identity: identity)?.versionID) == revisionID else {
            throw ContractError("revision was not the initial best version")
        }

        try await repository.adoptLyricsVersion(
            trackStableKey: identity.stableKey,
            lyricsVersionID: originalID
        )

        guard let adopted = try await repository.loadBestStored(track: track, identity: identity),
              adopted.versionID == originalID,
              adopted.document.lines.first?.originalText == "原始版本" else {
            throw ContractError("explicit version adoption did not change the best persisted version")
        }

        let restarted = SQLiteLyricsRepository(databaseURL: root.appendingPathComponent("lyrics.sqlite3"))
        try await restarted.prepare()
        guard let restored = try await restarted.loadBestStored(track: track, identity: identity),
              restored.versionID == originalID,
              restored.document.lines.first?.originalText == "原始版本" else {
            throw ContractError("adopted version did not survive repository restart")
        }

        let versionsAfter = try await restarted.loadEditableVersions(track: track, identity: identity)
        guard versionsAfter.count == versionsBefore.count,
              versionsAfter.contains(where: { $0.record.id == revisionID }) else {
            throw ContractError("explicit adoption removed or duplicated a version")
        }

        print("lyrics version switch contract passed")
    }
}

struct ContractError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String { message }
}

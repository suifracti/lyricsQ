import Foundation

@main
@MainActor
struct PersonalDataPackageContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpotifyLyricsPersonalDataPackageContract-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRepository = SQLiteLyricsRepository(
            databaseURL: root.appendingPathComponent("source.sqlite3")
        )
        try await sourceRepository.prepare()
        let sourcePackage = package(rawText: "原始歌词", contentHash: "lyrics-hash-a")
        try await sourceRepository.importPersonalLibraryPackage(sourcePackage)

        let exported = try await sourceRepository.exportPersonalDataPackage()
        try exported.validate()
        precondition(exported.manifest.schemaVersion == PersonalDataPackage.currentSchemaVersion)
        precondition(exported.manifest.packageType == "personal_data")
        precondition(exported.tracks.count == 1)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(exported)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PersonalDataPackage.self, from: encoded)
        precondition(decoded.manifest.schemaVersion == exported.manifest.schemaVersion)
        precondition(decoded.manifest.appVersion == exported.manifest.appVersion)
        precondition(decoded.manifest.packageType == exported.manifest.packageType)
        precondition(abs(decoded.manifest.createdAt.timeIntervalSince(exported.manifest.createdAt)) < 1.0)
        precondition(decoded.tracks.count == exported.tracks.count)
        assertTrackPackagesEqualIgnoringManifest(decoded.tracks[0], exported.tracks[0])

        let destinationRepository = SQLiteLyricsRepository(
            databaseURL: root.appendingPathComponent("destination.sqlite3")
        )
        try await destinationRepository.prepare()

        let initialPreview = try await destinationRepository.previewImportPersonalDataPackage(decoded)
        precondition(initialPreview.trackCount == 1)
        precondition(initialPreview.totalNewAssets == 4)
        precondition(!initialPreview.hasConflicts)

        try await destinationRepository.importPersonalDataPackage(decoded)
        let roundTripped = try await destinationRepository.exportPersonalDataPackage()
        precondition(roundTripped.tracks.count == exported.tracks.count)
        assertTrackPackagesEqualIgnoringManifest(roundTripped.tracks[0], exported.tracks[0])
        let roundTrippedTrack = roundTripped.tracks[0].track
        precondition(roundTrippedTrack.stableKey == "spotify-id:package-a")
        precondition(roundTrippedTrack.title == "Package Song")
        precondition(roundTrippedTrack.artist == "Package Artist")
        precondition(roundTrippedTrack.album == "Package Album")
        precondition(roundTripped.tracks[0].lyricsVersions[0].rawText == "原始歌词")
        precondition(roundTripped.tracks[0].translationVersions[0].lines[0].translatedText == "translated")
        precondition(roundTripped.tracks[0].readingVersions[0].lines[0].readingText == "yomi")
        precondition(roundTripped.tracks[0].timingVersions[0].spansPayload == "timing-payload")
        precondition(roundTripped.tracks[0].lyricsVersions[0].source == "manualImport")

        let conflictingPackage = PersonalDataPackage(
            manifest: decoded.manifest,
            tracks: [package(rawText: "篡改歌词", contentHash: "lyrics-hash-conflict")]
        )
        let conflictPreview = try await destinationRepository.previewImportPersonalDataPackage(conflictingPackage)
        precondition(conflictPreview.hasConflicts)
        do {
            try await destinationRepository.importPersonalDataPackage(conflictingPackage)
            preconditionFailure("conflicting package was imported")
        } catch {
            // Expected: existing conflict semantics reject the apply step.
        }
        let afterConflict = try await destinationRepository.exportPersonalDataPackage()
        precondition(afterConflict.tracks.count == roundTripped.tracks.count)
        assertTrackPackagesEqualIgnoringManifest(afterConflict.tracks[0], roundTripped.tracks[0])

        let newerPackage = PersonalDataPackage(
            manifest: .init(
                schemaVersion: PersonalDataPackage.currentSchemaVersion + 1,
                createdAt: decoded.manifest.createdAt,
                appVersion: decoded.manifest.appVersion,
                packageType: decoded.manifest.packageType
            ),
            tracks: decoded.tracks
        )
        do {
            try await destinationRepository.importPersonalDataPackage(newerPackage)
            preconditionFailure("newer package schema was accepted")
        } catch PersonalDataPackageError.unsupportedSchema(let version) {
            precondition(version == PersonalDataPackage.currentSchemaVersion + 1)
        }

        let emptyPackage = PersonalDataPackage(
            manifest: decoded.manifest,
            tracks: []
        )
        let emptyPreview = try await destinationRepository.previewImportPersonalDataPackage(emptyPackage)
        precondition(emptyPreview.trackCount == 0)
        precondition(emptyPreview.totalNewAssets == 0)
        try await destinationRepository.importPersonalDataPackage(emptyPackage)
        let afterEmptyImport = try await destinationRepository.exportPersonalDataPackage()
        precondition(afterEmptyImport.tracks.count == roundTripped.tracks.count)
        assertTrackPackagesEqualIgnoringManifest(afterEmptyImport.tracks[0], roundTripped.tracks[0])

        print("personal data package contract passed")
    }

    private static func assertTrackPackagesEqualIgnoringManifest(
        _ lhs: PersonalLyricsLibraryPackage,
        _ rhs: PersonalLyricsLibraryPackage
    ) {
        precondition(lhs.track == rhs.track)
        precondition(lhs.lyricsVersions == rhs.lyricsVersions)
        precondition(lhs.translationVersions == rhs.translationVersions)
        precondition(lhs.readingVersions == rhs.readingVersions)
        precondition(lhs.timingVersions == rhs.timingVersions)
    }

    private static func package(rawText: String, contentHash: String) -> PersonalLyricsLibraryPackage {
        let lyricsID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let translationID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let readingID = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
        let timingID = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
        let createdAt = Date(timeIntervalSince1970: 100)
        let updatedAt = Date(timeIntervalSince1970: 200)

        let track = PersonalLyricsLibraryPackage.PackageTrack(
            stableKey: "spotify-id:package-a",
            spotifyID: "package-a",
            spotifyURI: "spotify:track:package-a",
            isrc: "ISRC-PACKAGE-A",
            title: "Package Song",
            artist: "Package Artist",
            album: "Package Album",
            duration: 180,
            artworkURL: nil
        )
        let lyrics = PersonalLyricsLibraryPackage.PackageLyricsVersion(
            id: lyricsID,
            trackStableKey: track.stableKey,
            parentVersionID: nil,
            source: "manualImport",
            providerSourceID: "contract-source",
            language: "ja",
            isSynced: true,
            rawText: rawText,
            contentHash: contentHash,
            isMachineGenerated: false,
            isManuallyEdited: true,
            isLocked: false,
            confidence: 1,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lines: [
                .init(
                    lineIndex: 0,
                    startTime: 1,
                    endTime: 2,
                    originalText: "原文",
                    kanaText: "げんぶん",
                    romajiText: "genbun",
                    translationText: nil
                )
            ]
        )
        let translation = PersonalLyricsLibraryPackage.PackageTranslationVersion(
            id: translationID,
            lyricsVersionID: lyricsID,
            parentVersionID: nil,
            sourceKind: "manual",
            targetLanguage: "en",
            model: "contract",
            sourceContentHash: contentHash,
            isMachineGenerated: false,
            isManuallyEdited: true,
            isLocked: false,
            isArchived: false,
            status: "complete",
            confidence: 1,
            engineID: "contract-engine",
            promptPresetID: "contract-preset",
            createdAt: createdAt,
            updatedAt: updatedAt,
            lines: [.init(lineIndex: 0, translatedText: "translated")]
        )
        let reading = PersonalLyricsLibraryPackage.PackageReadingVersion(
            id: readingID,
            lyricsVersionID: lyricsID,
            parentVersionID: nil,
            sourceContentHash: contentHash,
            engineID: "contract-engine",
            representationID: "kana",
            sourceKind: "manual",
            language: "ja",
            isMachineGenerated: false,
            isManuallyEdited: true,
            isCurrent: true,
            isLocked: false,
            isArchived: false,
            confidence: 1,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lines: [
                .init(
                    lineIndex: 0,
                    originalText: "原文",
                    readingText: "yomi",
                    tokensJSON: "[]",
                    language: "ja",
                    source: "manual"
                )
            ]
        )
        let timing = PersonalLyricsLibraryPackage.PackageTimingVersion(
            id: timingID,
            lyricsVersionID: lyricsID,
            source: "automaticAlignment",
            granularity: "word",
            sourceContentHash: contentHash,
            spansPayload: "timing-payload",
            createdAt: createdAt
        )

        return PersonalLyricsLibraryPackage(
            track: track,
            lyricsVersions: [lyrics],
            translationVersions: [translation],
            readingVersions: [reading],
            timingVersions: [timing]
        )
    }
}

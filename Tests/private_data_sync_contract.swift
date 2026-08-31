import Foundation

@main
@MainActor
struct PrivateDataSyncContract {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpotifyLyricsPrivateDataSyncContract-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let syncFolder = root.appendingPathComponent("sync", isDirectory: true)
        try FileManager.default.createDirectory(at: syncFolder, withIntermediateDirectories: true)

        let suiteName = "SpotifyLyricsPrivateDataSyncContract-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        try PersonalDataSyncStore.saveFolderReference(syncFolder, defaults: defaults)
        let restoredFolder = PersonalDataSyncStore.restoreFolderReference(defaults: defaults)
        precondition(restoredFolder?.standardizedFileURL.path == syncFolder.standardizedFileURL.path)

        let sourcePackage = package(rawText: "sync lyrics", contentHash: "sync-hash")
        try PersonalDataSyncStore.write(sourcePackage, to: syncFolder)
        let packageURL = PersonalDataSyncStore.packageURL(in: syncFolder)
        precondition(FileManager.default.fileExists(atPath: packageURL.path))
        let writtenData = try Data(contentsOf: packageURL)
        precondition(!writtenData.isEmpty)
        let temporaryFiles = try FileManager.default.contentsOfDirectory(
            at: syncFolder,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.contains(".tmp") }
        precondition(temporaryFiles.isEmpty)

        guard let readPackage = try PersonalDataSyncStore.read(from: syncFolder) else {
            preconditionFailure("written package could not be read")
        }
        assertTrackPackagesEqualIgnoringManifest(readPackage.tracks[0], sourcePackage.tracks[0])
        precondition(readPackage.manifest.schemaVersion == sourcePackage.manifest.schemaVersion)
        precondition(readPackage.manifest.packageType == sourcePackage.manifest.packageType)

        let destinationRepository = SQLiteLyricsRepository(
            databaseURL: root.appendingPathComponent("destination.sqlite3")
        )
        try await destinationRepository.prepare()
        let initialPreview = try await destinationRepository.previewImportPersonalDataPackage(readPackage)
        precondition(!initialPreview.hasConflicts)
        precondition(initialPreview.totalNewAssets == 4)
        try await destinationRepository.importPersonalDataPackage(readPackage)

        let conflictingPackage = PersonalDataPackage(
            manifest: readPackage.manifest,
            tracks: [Self.package(rawText: "changed lyrics", contentHash: "conflict-hash").tracks[0]]
        )
        let conflictPreview = try await destinationRepository.previewImportPersonalDataPackage(conflictingPackage)
        precondition(conflictPreview.hasConflicts)
        do {
            try await destinationRepository.importPersonalDataPackage(conflictingPackage)
            preconditionFailure("conflicting package was silently applied")
        } catch {
            // Expected: existing conflict semantics reject the apply step.
        }
        let unchanged = try await destinationRepository.exportPersonalDataPackage()
        assertTrackPackagesEqualIgnoringManifest(unchanged.tracks[0], readPackage.tracks[0])

        let newerPackage = PersonalDataPackage(
            manifest: .init(
                schemaVersion: PersonalDataPackage.currentSchemaVersion + 1,
                createdAt: readPackage.manifest.createdAt,
                appVersion: readPackage.manifest.appVersion,
                packageType: readPackage.manifest.packageType
            ),
            tracks: readPackage.tracks
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let newerData = try encoder.encode(newerPackage)
        do {
            _ = try PersonalDataSyncStore.decode(newerData)
            preconditionFailure("newer package schema was accepted")
        } catch PersonalDataPackageError.unsupportedSchema(let version) {
            precondition(version == PersonalDataPackage.currentSchemaVersion + 1)
        }

        let missingFolder = root.appendingPathComponent("missing", isDirectory: true)
        try FileManager.default.createDirectory(at: missingFolder, withIntermediateDirectories: true)
        let missingPackage = try PersonalDataSyncStore.read(from: missingFolder)
        precondition(missingPackage == nil)

        print("private data sync contract passed")
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

    private static func package(rawText: String, contentHash: String) -> PersonalDataPackage {
        let lyricsID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let translationID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let readingID = UUID(uuidString: "00000000-0000-0000-0000-000000000203")!
        let timingID = UUID(uuidString: "00000000-0000-0000-0000-000000000204")!
        let createdAt = Date(timeIntervalSince1970: 300)
        let updatedAt = Date(timeIntervalSince1970: 400)

        let track = PersonalLyricsLibraryPackage.PackageTrack(
            stableKey: "spotify-id:sync-a",
            spotifyID: "sync-a",
            spotifyURI: "spotify:track:sync-a",
            isrc: "ISRC-SYNC-A",
            title: "Sync Song",
            artist: "Sync Artist",
            album: "Sync Album",
            duration: 200,
            artworkURL: nil
        )
        let lyrics = PersonalLyricsLibraryPackage.PackageLyricsVersion(
            id: lyricsID,
            trackStableKey: track.stableKey,
            parentVersionID: nil,
            source: "manualImport",
            providerSourceID: "sync-source",
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
                    startTime: 0,
                    endTime: 1,
                    originalText: rawText,
                    kanaText: nil,
                    romajiText: nil,
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
            engineID: "contract",
            promptPresetID: "contract",
            createdAt: createdAt,
            updatedAt: updatedAt,
            lines: [.init(lineIndex: 0, translatedText: "translated")]
        )
        let reading = PersonalLyricsLibraryPackage.PackageReadingVersion(
            id: readingID,
            lyricsVersionID: lyricsID,
            parentVersionID: nil,
            sourceContentHash: contentHash,
            engineID: "contract",
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
            lines: [.init(lineIndex: 0, originalText: rawText, readingText: "よみ", tokensJSON: "[]", language: "ja", source: "manual")]
        )
        let timing = PersonalLyricsLibraryPackage.PackageTimingVersion(
            id: timingID,
            lyricsVersionID: lyricsID,
            source: "manual",
            granularity: "line",
            sourceContentHash: contentHash,
            spansPayload: "timing-payload",
            createdAt: createdAt
        )
        let singlePackage = PersonalLyricsLibraryPackage(
            track: track,
            lyricsVersions: [lyrics],
            translationVersions: [translation],
            readingVersions: [reading],
            timingVersions: [timing]
        )
        return PersonalDataPackage(tracks: [singlePackage])
    }
}

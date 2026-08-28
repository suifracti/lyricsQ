import Foundation
#if canImport(SQLite3)
import SQLite3
#endif

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

@main
struct TimingPersistenceImmutableContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            fflush(stdout)
            exit(1)
        }
    }

    static func log(_ msg: String) {
        print(msg)
        fflush(stdout)
    }

    static func main() async throws {
        let dbURL = URL(fileURLWithPath: "/tmp/test_timing_immutable_\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: dbURL) }

        let repo = SQLiteLyricsRepository(databaseURL: dbURL)
        try await repo.prepare()

        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 200,
            spotifyId: "test_spotify_id"
        )
        let identity = TrackIdentity(track: track)

        let line0SpansA = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 2.0, endTime: 3.0, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]

        let linesA = [
            LyricLine(timestamp: 1.0, originalText: "Hello World", endTime: 3.0, performerID: "v1", timedSpans: line0SpansA),
            LyricLine(timestamp: 4.0, originalText: "Second Line", endTime: 6.0)
        ]

        let timingVersionAID = UUID()
        let docA = LyricsDocument(
            identity: identity,
            lines: linesA,
            isSynchronized: true,
            source: .amll,
            confidence: 1.0,
            providerSourceID: "amll:test_spotify_id",
            spotifyTrackID: "test_spotify_id",
            timingVersionID: timingVersionAID
        )

        // 1. Save document with Timing Version A
        log("[Step 1] Saving document with Timing Version A...")
        let saveResultA = try await repo.save(track: track, identity: identity, document: docA)
        guard let lyricsVersionID = saveResultA.versionID else {
            log("FAIL: Expected versionID from save A")
            exit(1)
        }
        log("  - lyricsVersionID: \(lyricsVersionID), sourceContentHash: \(saveResultA.sourceContentHash ?? "")")

        // 2. Load stored document: must return Timing Version A
        log("[Step 2] Loading stored document...")
        guard let storedA = try await repo.loadBestStored(track: track, identity: identity) else {
            log("FAIL: Expected stored document to be found")
            exit(1)
        }
        assertRule(storedA.document.hasTimedSpans, "Stored document must have hasTimedSpans == true")
        assertRule(storedA.document.timingVersionID == timingVersionAID, "Stored document timingVersionID must match A")
        let baseHashA = storedA.sourceContentHash
        log("  - loaded timingVersionID: \(storedA.document.timingVersionID!), baseHash: \(baseHashA ?? "")")

        // 3. Re-save the exact loaded document with existing timingVersionID = A (Idempotency Test)
        log("[Step 3] Re-saving exact loaded document (Idempotency)...")
        let resaveResult = try await repo.save(track: track, identity: identity, document: storedA.document)
        assertRule(resaveResult.versionID == lyricsVersionID, "Re-save must return same lyricsVersionID")
        assertRule(resaveResult.sourceContentHash == baseHashA, "Re-save must return identical sourceContentHash")
        log("  - re-save succeeded without error (disposition: \(resaveResult.disposition))")

        // 4. Verify timing count is still 1 (no duplicate insertion or constraint failure)
        log("[Step 4] Checking row count in SQLite after re-save...")
        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            log("FAIL: Cannot open sqlite database")
            exit(1)
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM lyrics_timing_versions WHERE lyrics_version_id = ?;", -1, &stmt, nil) == SQLITE_OK else {
            log("FAIL: Failed to prepare select query")
            exit(1)
        }
        sqlite3_bind_text(stmt, 1, lyricsVersionID.uuidString, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            log("FAIL: Step failed")
            exit(1)
        }
        let countAfterResave = sqlite3_column_int(stmt, 0)
        sqlite3_finalize(stmt)
        assertRule(countAfterResave == 1, "Idempotent re-save must keep timing row count == 1, got \(countAfterResave)")
        log("  - timing row count is 1 (idempotent no-op confirmed)")

        // 4b. Modified payload with same timingVersionID = A must throw integrity error
        log("[Step 4b] Attempting to save modified payload with reused timingVersionID = A...")
        let line0AlteredSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.5, endTime: 2.5, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 2.5, endTime: 3.0, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]
        let alteredLinesA = [
            LyricLine(timestamp: 1.0, originalText: "Hello World", endTime: 3.0, performerID: "v1", timedSpans: line0AlteredSpans),
            LyricLine(timestamp: 4.0, originalText: "Second Line", endTime: 6.0)
        ]
        let docAlteredPayload = LyricsDocument(
            identity: identity,
            lines: alteredLinesA,
            isSynchronized: true,
            source: .amll,
            confidence: 1.0,
            providerSourceID: "amll:test_spotify_id",
            spotifyTrackID: "test_spotify_id",
            timingVersionID: timingVersionAID // Reusing ID A but with different timestamps
        )
        do {
            _ = try await repo.save(track: track, identity: identity, document: docAlteredPayload)
            log("FAIL: Reusing timingVersionID A with altered payload must throw integrity violation")
            exit(1)
        } catch {
            log("  - expected integrity error caught when payload differed: \(error)")
        }

        // Verify count is still 1 and original payload is intact
        guard let storedAfterAttempt = try await repo.loadBestStored(track: track, identity: identity) else {
            log("FAIL: Stored document must still exist")
            exit(1)
        }
        assertRule(storedAfterAttempt.document.lines[0].timedSpans?[0].startTime == 1.0, "Timing A payload must remain unchanged (1.0s, not 1.5s)")
        log("  - original Timing A payload preserved without mutation")

        // 5. Save Timing Version B (updated timing spans, same lyrics text, new UUID)
        log("[Step 5] Saving Timing Version B (new UUID, immutable append)...")
        try await Task.sleep(nanoseconds: 100_000_000)

        let line0SpansB = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.1, endTime: 1.9, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 1.9, endTime: 2.9, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]
        let linesB = [
            LyricLine(timestamp: 1.0, originalText: "Hello World", endTime: 3.0, performerID: "v1", timedSpans: line0SpansB),
            LyricLine(timestamp: 4.0, originalText: "Second Line", endTime: 6.0)
        ]
        let timingVersionBID = UUID()
        let docB = LyricsDocument(
            identity: identity,
            lines: linesB,
            isSynchronized: true,
            source: .amll,
            confidence: 1.0,
            providerSourceID: "amll:test_spotify_id",
            spotifyTrackID: "test_spotify_id",
            timingVersionID: timingVersionBID
        )

        let saveResultB = try await repo.save(track: track, identity: identity, document: docB)
        log("  - save B versionID: \(saveResultB.versionID!), hash: \(saveResultB.sourceContentHash ?? "")")

        // 6. Load stored document: must adopt latest compatible timing version B
        log("[Step 6] Loading stored document: verifying latest compatible wins...")
        guard let storedB = try await repo.loadBestStored(track: track, identity: identity) else {
            log("FAIL: Expected stored document B")
            exit(1)
        }
        assertRule(storedB.sourceContentHash == baseHashA, "Source content hash must remain 100% identical")
        assertRule(storedB.document.timingVersionID == timingVersionBID, "Stored document must adopt latest timing version B")
        assertRule(storedB.document.lines[0].timedSpans?[0].startTime == 1.1, "Spans must reflect timing version B")
        log("  - adopted latest timing version B: \(timingVersionBID)")

        // 7. Immutability validation: Both timing version A and B must exist in SQLite table (count == 2)
        log("[Step 7] Checking row count in SQLite after version B...")
        var stmt2: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM lyrics_timing_versions WHERE lyrics_version_id = ?;", -1, &stmt2, nil) == SQLITE_OK else {
            log("FAIL: Failed to prepare select query 2")
            exit(1)
        }
        sqlite3_bind_text(stmt2, 1, lyricsVersionID.uuidString, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt2) == SQLITE_ROW else {
            log("FAIL: Step 2 failed")
            exit(1)
        }
        let timingCount = sqlite3_column_int(stmt2, 0)
        sqlite3_finalize(stmt2)
        assertRule(timingCount == 2, "Expected 2 immutable timing versions in SQLite, got \(timingCount)")
        log("  - timing row count is 2 (immutable append confirmed)")

        // 8. Integrity check: Re-saving with mismatched hash/lyricsVersionID fails closed
        log("[Step 8] Checking integrity violation fails closed...")
        let mismatchedDoc = LyricsDocument(
            identity: identity,
            lines: [LyricLine(timestamp: 1.0, originalText: "Completely Different Text", endTime: 3.0, performerID: "v1", timedSpans: line0SpansA)],
            isSynchronized: true,
            source: .amll,
            confidence: 1.0,
            providerSourceID: "amll:test_spotify_id_different",
            spotifyTrackID: "test_spotify_id_different",
            timingVersionID: timingVersionAID // Reusing ID A with different text
        )
        do {
            _ = try await repo.save(track: track, identity: identity, document: mismatchedDoc)
            log("FAIL: Expected integrity violation to throw error")
            exit(1)
        } catch {
            log("  - expected integrity error caught: \(error)")
        }

        log("PASS: Timing persistence immutable & idempotent re-save contract verified")
    }
}

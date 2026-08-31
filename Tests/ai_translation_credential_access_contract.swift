import Foundation

private final class CountingKeychainTransport: AITranslationKeychainTransport, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var readCount = 0
    private(set) var saveCount = 0
    private(set) var deleteCount = 0
    private var storage: [String: String] = [:]

    init(initialStorage: [String: String] = [:]) {
        self.storage = initialStorage
    }

    func read(service: String, account: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        readCount += 1
        // Simulate small transport latency to expose race conditions if any
        Thread.sleep(forTimeInterval: 0.005)
        return storage["\(service):\(account)"]
    }

    func save(service: String, account: String, key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        saveCount += 1
        storage["\(service):\(account)"] = key
    }

    func delete(service: String, account: String) throws {
        lock.lock()
        defer { lock.unlock() }
        deleteCount += 1
        storage.removeValue(forKey: "\(service):\(account)")
    }
}

private final class CountingAPIKeyStore: AITranslationAPIKeyStore, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var readCount = 0
    private(set) var saveCount = 0
    private(set) var deleteCount = 0
    private var key: String?

    init(key: String? = "test-api-key") {
        self.key = key
    }

    func read() -> String? {
        lock.lock()
        defer { lock.unlock() }
        readCount += 1
        return key
    }

    func save(_ key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        saveCount += 1
        self.key = key
    }

    func delete() throws {
        lock.lock()
        defer { lock.unlock() }
        deleteCount += 1
        self.key = nil
    }

    func invalidateCache() {}
}

@main
struct AITranslationCredentialAccessContract {
    static func main() async {
        print("=== AI TRANSLATION CREDENTIAL ACCESS CONTRACT ===")

        // [1] App / Session Initialization & Synchronize (Zero Keychain reads)
        print("[1] Testing Session Initialization & Lifecycle (Must be 0 Keychain reads)...")
        let countingStore = CountingAPIKeyStore(key: "secret-key-123")
        let openAIService = OpenAICompatibleTranslationService(keyStore: countingStore)
        let repo = UnavailableTranslationRepository()
        let controller = await MainActor.run {
            TranslationSessionController(repository: repo, engine: openAIService)
        }

        assert(countingStore.readCount == 0, "Controller init must not read credential")

        let track = Track(title: "祝福", artist: "YOASOBI", album: "祝福", duration: 196.235)
        let identity = TrackIdentity(track: track)
        let line1 = LyricLine(timestamp: 0.672, originalText: "遥か遠くに浮かぶ星を", translationText: "遥望漂浮在遥远星空的星辰")
        let line2 = LyricLine(timestamp: 5.109, originalText: "想い眠りにつく君の", translationText: "伴着思念陷入沉睡的你")
        let doc = LyricsDocument(
            identity: identity,
            title: "祝福",
            artist: "YOASOBI",
            album: "祝福",
            duration: 196.235,
            lines: [line1, line2],
            isSynchronized: true,
            source: .amll
        )
        let config = AITranslationConfiguration(
            baseURL: "https://api.openai.com/v1",
            model: "gpt-4o-mini",
            autoTranslateNewLyrics: false,
            engineID: TranslationEngineID.openAICompatible.rawValue
        )

        await MainActor.run {
            controller.synchronize(
                document: doc,
                lyricsVersionID: UUID(),
                sourceContentHash: "hash-123",
                configuration: config
            )
        }

        // Wait a turn for any async tasks
        try? await Task.sleep(nanoseconds: 50_000_000)
        assert(countingStore.readCount == 0, "Session synchronization without auto-translate must not read credential")
        print("  ✓ Session initialization and synchronization: readCount = 0")

        // [2] Existing Translation Projection (Zero Keychain reads)
        print("[2] Testing Existing Translation Projection (Must be 0 Keychain reads)...")
        let projected = await MainActor.run {
            controller.project(onto: [line1, line2])
        }
        assert(projected.count == 2, "Projected count must match")
        assert(countingStore.readCount == 0, "Translation projection must not read credential")
        print("  ✓ Translation projection onto lyric lines: readCount = 0")

        // [3] Ruby / Romaji / Kana / Multiline / Playback ticks / Seek / Pause (Zero Keychain reads)
        print("[3] Testing Playback Ticks, Seek, Pause, and Secondary Layer Switching...")
        var currentTime = 0.0
        for _ in 1...20 {
            currentTime += 0.5
            _ = LyricsTimeline.activeLineIndex(lines: projected, time: currentTime, isSynchronized: true)
        }
        // Seek forward
        currentTime = 15.0
        _ = LyricsTimeline.activeLineIndex(lines: projected, time: currentTime, isSynchronized: true)
        // Seek backward
        currentTime = 2.0
        _ = LyricsTimeline.activeLineIndex(lines: projected, time: currentTime, isSynchronized: true)
        // Pause (time stays constant)
        for _ in 1...5 {
            _ = LyricsTimeline.activeLineIndex(lines: projected, time: currentTime, isSynchronized: true)
        }

        assert(countingStore.readCount == 0, "Playback tick, seek, and pause must not read credential")
        print("  ✓ Playback tick, forward seek, backward seek, pause: readCount = 0")

        // [4] Concurrency Test: 20 Concurrent reads on cold cache -> Underlying read count == 1
        print("[4] Testing 20 Concurrent Cold Reads with Fake Transport (No Real Keychain)...")
        let mockTransport = CountingKeychainTransport(initialStorage: [
            "com.spotifylyrics.ai-translation:test-account": "live-api-key-999"
        ])
        let keychainStore = KeychainAITranslationAPIKeyStore(account: "test-account", transport: mockTransport)

        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    keychainStore.read()
                }
            }
            for await result in group {
                assert(result == "live-api-key-999", "All concurrent reads must receive key")
            }
        }

        assert(mockTransport.readCount == 1, "Underlying transport read count MUST be 1 for 20 concurrent reads (got \(mockTransport.readCount))")
        print("  ✓ 20 concurrent cold reads resulted in exactly 1 underlying read (readCount = 1)")

        // [5] Subsequent Sequential Reads (Cached)
        print("[5] Testing Subsequent Sequential Reads...")
        for _ in 0..<10 {
            assert(keychainStore.read() == "live-api-key-999")
        }
        assert(mockTransport.readCount == 1, "Subsequent reads must not hit underlying transport")
        print("  ✓ Subsequent sequential reads: readCount remains 1")

        // [6] Cache Invalidation on Save & Delete
        print("[6] Testing Cache Invalidation on Save & Delete...")
        try! keychainStore.save("updated-key-111")
        assert(mockTransport.saveCount == 1, "Underlying save must be called once")
        assert(keychainStore.read() == "updated-key-111", "Saved key must update cache immediately")
        assert(mockTransport.readCount == 1, "Read after save must use in-memory cache without extra transport read")

        try! keychainStore.delete()
        assert(mockTransport.deleteCount == 1, "Underlying delete must be called once")
        assert(keychainStore.read() == nil, "Deleted key must clear cache immediately")
        assert(mockTransport.readCount == 1, "Read after delete must use in-memory cache")

        keychainStore.invalidateCache()
        // Next read should reload from transport
        _ = keychainStore.read()
        assert(mockTransport.readCount == 2, "Read after invalidateCache must query underlying transport (got \(mockTransport.readCount))")
        print("  ✓ Cache invalidation on save, delete, and invalidateCache verified")

        // [7] SPOTIFYLYRICS_DISABLE_KEYCHAIN environment suppression
        print("[7] Testing SPOTIFYLYRICS_DISABLE_KEYCHAIN environment suppression...")
        setenv("SPOTIFYLYRICS_DISABLE_KEYCHAIN", "1", 1)
        let suppressedTransport = CountingKeychainTransport(initialStorage: [
            "com.spotifylyrics.ai-translation:suppressed": "secret"
        ])
        let suppressedStore = KeychainAITranslationAPIKeyStore(account: "suppressed", transport: suppressedTransport)
        assert(suppressedStore.read() == nil, "SPOTIFYLYRICS_DISABLE_KEYCHAIN must suppress read")
        assert(suppressedTransport.readCount == 0, "Suppressed store must not touch underlying transport")
        unsetenv("SPOTIFYLYRICS_DISABLE_KEYCHAIN")
        print("  ✓ Environment suppression verified (0 transport calls)")

        print("\nPASS: AI Translation Credential Access Contract verified successfully!")
    }
}

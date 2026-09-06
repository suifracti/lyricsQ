import Foundation

private actor ProbeLedger {
    var active = 0
    var peak = 0
    var starts: [String] = []
    var finishes: [String] = []
    func begin(_ name: String) { active += 1; peak = max(peak, active); starts.append(name) }
    func end(_ name: String) { active -= 1; finishes.append(name) }
    func snapshot() -> (Int, Int, [String], [String]) { (active, peak, starts, finishes) }
}
private struct ProbeProvider: LyricsProvider {
    let name: String
    let executionLane: LyricsProviderExecutionLane
    let delay: UInt64
    let ledger: ProbeLedger
    let source: LyricsSource
    var timeoutInterval: TimeInterval { 4 }
    func lookup(track: Track, identity: TrackIdentity) async -> LyricsLookupResult {
        await ledger.begin(name)
        do { try await Task.sleep(nanoseconds: delay) }
        catch { await ledger.end(name); return .failed(.cancelled) }
        await ledger.end(name)
        return .match(LyricsDocument(identity: identity, title: track.title, artist: track.artist,
            album: track.album, duration: track.duration,
            lines: [LyricLine(timestamp: 1, originalText: "Fixture text")],
            source: source, providerSourceID: name))
    }
}
@main struct SearchConcurrencyManualContract {
    static func main() async {
        let track = Track(title: "Contract song", artist: "Contract artist", album: "Contract album", duration: 180)
        let identity = TrackIdentity(track: track)
        let ledger = ProbeLedger()
        let providers = (0..<7).map { ProbeProvider(name: "priority-\($0)", executionLane: .network,
            delay: $0 == 0 ? 180_000_000 : 60_000_000, ledger: ledger, source: .lrclib) }
        let result = await LyricsSearchManager(providers: providers).lookup(track: track, identity: identity)
        guard case .match(let chosen) = result else { fatalError("expected automatic candidate") }
        precondition(chosen.providerSourceID == "priority-0", "completion order must not change configured priority")
        let network = await ledger.snapshot()
        precondition(network.0 == 0 && network.1 == 3 && network.2.count == 7, "network peak must be exactly3 and fully drained")
        let localLedger = ProbeLedger()
        let local = ProbeProvider(name: "local", executionLane: .local, delay: 1, ledger: localLedger, source: .local)
        let online = ProbeProvider(name: "must-not-start", executionLane: .network, delay: 1, ledger: localLedger, source: .lrclib)
        guard case .match(let localChoice) = await LyricsSearchManager(providers: [online, local]).lookup(track: track, identity: identity) else { fatalError("local match") }
        precondition(localChoice.source == .local)
        let localRun = await localLedger.snapshot()
        precondition(localRun.2 == ["local"], "local match must skip all online probes")
        let manual = LyricsCandidate(id: "body", identity: identity, title: track.title, artist: track.artist, album: track.album,
            duration: track.duration, lines: [LyricLine(timestamp: 0, originalText: "Body")], source: .lyricsOVH,
            confidence: 1, spotifyTrackID: track.spotifyId, isrc: track.isrc)
        let decision = LyricsSafeMatcher.decide(candidate: manual, metadata: TrackMetadata.bootstrap(from: track))
        precondition(decision.tier == .candidates && !decision.hardReject)
        let empty = LyricsCandidate(id: "empty", identity: identity, title: track.title, artist: track.artist, album: track.album,
            duration: track.duration, lines: [LyricLine(timestamp: 0, originalText: "   ")], source: .lyricsOVH, confidence: 1)
        let emptyDecision = LyricsSafeMatcher.decide(candidate: empty, metadata: TrackMetadata.bootstrap(from: track))
        precondition(emptyDecision.tier == .reject && emptyDecision.hardReject)
        let ovhLedger = ProbeLedger()
        let ovh = ProbeProvider(name: "OVH", executionLane: .network, delay: 1, ledger: ovhLedger, source: .lyricsOVH)
        guard case .candidates(let visible) = await LyricsSearchManager(providers: [ovh]).lookup(track: track, identity: identity), !visible.isEmpty else { fatalError("OVH body must remain visible and never auto-adopt even if provider returns match") }
        precondition(visible.allSatisfy { $0.source == .lyricsOVH && $0.displayedConfidence == 0 })
        print("PASS peak3, configured priority, local-first, OVH manual-only visible candidate")
        fflush(stdout)

        // One result finishes before cancellation while the bounded group is
        // still awaiting other providers. It must never be adopted afterward.
        let cancelLedger = ProbeLedger()
        let cancellingProviders = (0..<7).map { ProbeProvider(name: "cancel-\($0)", executionLane: .network,
            delay: $0 == 0 ? 20_000_000 : 2_000_000_000, ledger: cancelLedger, source: .lrclib) }
        let task = Task { await LyricsSearchManager(providers: cancellingProviders).lookup(track: track, identity: identity) }
        for _ in 0..<1000 {
            if await cancelLedger.snapshot().3.contains("cancel-0") { break }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        let beforeCancel = await cancelLedger.snapshot()
        precondition(beforeCancel.3.contains("cancel-0"))
        task.cancel()
        let cancelled = await task.value
        guard case .failed(.cancelled) = cancelled else { fatalError("cancelled search adopted previously completed network result") }
        let end = await cancelLedger.snapshot()
        precondition(end.0 == 0 && end.2.count <= 4, "cancellation must drain active work and stop queued providers")
        print("PASS cancellation drains active probes and blocks adoption of buffered successes")
    }
}

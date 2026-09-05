import Foundation

private actor RecordingProvider: LyricsProvider {
    let name = "Recording fixture"
    var probes: [(Track, TrackIdentity)] = []
    func lookup(track: Track, identity: TrackIdentity) async -> LyricsLookupResult {
        probes.append((track, identity)); return .noMatch
    }
}
private final class QuerySession: LRCLIBSession {
    var requests: [URLRequest] = []
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
        let broad = request.url!.lastPathComponent == "search" && !items.contains { $0.name == "artist_name" || $0.name == "track_name" }
        let payload = broad ? #"[{"id":42,"trackName":"Marigold","artistName":"Aimyon","albumName":"Marigold","duration":307,"syncedLyrics":"[00:01.00]Generated fixture"}]"# : "[]"
        return (Data(payload.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
@main struct TitleOnlyRecoveryContract {
    static func main() async {
        let track = Track(title: "Marigold", artist: "愛繆", album: "Momentary Sixth Sense", duration: 306, spotifyId: "original-track")
        let identity = TrackIdentity(track: track)
        let mode = CommandLine.arguments.dropFirst().first ?? "all"
        if mode == "manager" || mode == "all" {
            let provider = RecordingProvider()
            _ = await LyricsSearchManager(providers: [provider]).lookup(track: track, identity: identity)
            let probes = await provider.probes
            precondition(probes.contains { $0.0.artist.isEmpty }, "title-only probe must not restore the original artist")
            precondition(probes.contains { $0.0.artist == track.artist }, "strict probes keep their artist")
            precondition(probes.allSatisfy { $0.1 == identity && $0.0.spotifyId == track.spotifyId }, "query changes cannot change request identity")
        }
        if mode == "provider" || mode == "all" {
            let session = QuerySession()
            let probe = Track(title: "Marigold Aimyon", artist: "", album: track.album, duration: track.duration)
            _ = await LRCLIBLyricsProvider(session: session, baseURL: URL(string: "https://fixture.invalid/api")!).lookup(track: probe, identity: identity)
            precondition(session.requests.count == 1 && session.requests[0].url!.lastPathComponent == "search", "artist-free probe must use search directly")
            let items = URLComponents(url: session.requests[0].url!, resolvingAgainstBaseURL: false)!.queryItems!
            precondition(items == [URLQueryItem(name: "q", value: "Marigold Aimyon")], "free-text search must not add contradictory structured filters")
        }
        if mode == "matcher" || mode == "all" {
            let candidate = LyricsCandidate(id: "fixture", identity: identity, title: "Marigold", artist: "Aimyon", album: "Marigold", duration: 307, lines: [LyricLine(timestamp: 1, originalText: "Generated fixture")], source: .lrclib, confidence: 0.6)
            let metadata = TrackMetadata.bootstrap(from: track)
            let manual = LyricsQueryVariant(rank: 0, strategy: .manualOverride, queryKind: .manualOverride, titleQuery: "Marigold", artistQuery: nil)
            let decision = LyricsSafeMatcher.decide(candidate: candidate, metadata: metadata, queryVariant: manual)
            precondition(decision.tier == .candidates, "manual exact-title recovery with an unresolved artist must remain selectable, never automatic")
            precondition(LyricsSafeMatcher.decide(candidate: candidate, metadata: metadata).tier == .reject, "automatic cross-artist guard stays strict")
            let unrelated = LyricsQueryVariant(rank: 0, strategy: .manualOverride, queryKind: .manualOverride, titleQuery: "Unrelated song", artistQuery: nil)
            precondition(LyricsSafeMatcher.decide(candidate: candidate, metadata: metadata, queryVariant: unrelated).tier == .reject, "unrelated manual terms do not unlock cross-artist candidates")
            let conflict = LyricsCandidate(id: "conflict", identity: identity, title: candidate.title, artist: candidate.artist, album: candidate.album, duration: candidate.duration, lines: candidate.lines, source: .lrclib, confidence: 0.6, spotifyTrackID: "different-track")
            precondition(LyricsSafeMatcher.decide(candidate: conflict, metadata: metadata, queryVariant: manual).tier == .reject, "manual query cannot bypass an independent ID conflict")
        }
        if mode == "integration" || mode == "all" || mode == "live" {
            let provider: LRCLIBLyricsProvider = mode == "live" ? LRCLIBLyricsProvider(timeout: 5, maxAutomaticRetries: 0) : LRCLIBLyricsProvider(session: QuerySession(), baseURL: URL(string: "https://fixture.invalid/api")!)
            let result = await LyricsSearchManager(providers: [provider]).lookup(track: track, identity: identity, queryOverride: "Marigold Aimyon")
            guard case .candidates(let candidates) = result else { fatalError("expected explicit candidates from manual recovery") }
            precondition(candidates.allSatisfy { $0.identity == identity }, "candidate identity must remain the original playback track")
            print("RECOVERED_CANDIDATES", candidates.map { "\($0.title)|\($0.artist)|\($0.duration)|\($0.providerSourceID ?? "")" })
        }
        print("title-only recovery", mode, "PASS")
    }
}

import Foundation

// Live chain verified 2026-09-06 with 稻香 / 周杰伦 by the health-check task:
// search → returned hash → returned lyric ID/key → base64 LRC, 53 timed lines.
// Requests took 1.210 s / 1.856 s / 1.833 s; no keys or lyrics were persisted.
// This contract uses synthetic lyrics and URLProtocol, never the live service.
private final class KugouFixtureProtocol: URLProtocol, @unchecked Sendable {
    struct Reply { var body: Data; var status = 200; var error: URLError? }
    static var replies: [Reply] = []
    static var requests: [URLRequest] = []
    static var pending = false
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        if Self.pending { return }
        precondition(!Self.replies.isEmpty, "unexpected extra request")
        let reply = Self.replies.removeFirst()
        if let error = reply.error { client?.urlProtocol(self, didFailWithError: error); return }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct KugouContract {
    static func main() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [KugouFixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let provider = KugouExperimentalLyricsProvider(session: session, timeout: 4)
        let track = Track(title: "Query & Title", artist: "Query Artist", album: "Wrong Album", duration: 999)
        let identity = TrackIdentity(track: track)
        func json(_ value: Any, status: Int = 200) -> KugouFixtureProtocol.Reply {
            .init(body: try! JSONSerialization.data(withJSONObject: value), status: status)
        }
        func catalog(_ count: Int = 1) -> KugouFixtureProtocol.Reply {
            json(["data": ["lists": (1...count).map { n in ["FileHash": "hash\(n)", "SongName": "Returned Title \(n)", "SingerName": "Returned Artist", "AlbumName": "Returned Album", "Duration": 245, "MixSongID": n] as [String: Any] }]])
        }
        func lyricSearch(_ id: Int = 101) -> KugouFixtureProtocol.Reply {
            json(["candidates": [["id": id, "accesskey": "fixture-key&only"]]])
        }
        func lyrics(_ text: String = "[00:01.20]Synthetic one\n[00:03.40]Synthetic two") -> KugouFixtureProtocol.Reply {
            json(["content": Data(text.utf8).base64EncodedString()])
        }
        func reset(_ replies: [KugouFixtureProtocol.Reply]) {
            KugouFixtureProtocol.replies = replies
            KugouFixtureProtocol.requests = []
        }
        reset([catalog(), lyricSearch(), lyrics()])
        guard case .candidates(let values) = await provider.lookup(track: track, identity: identity), let first = values.first else { fatalError("must use shared matcher candidate path") }
        precondition(values.count == 1 && first.source == .kugouExperimental)
        precondition(first.title == "Returned Title 1" && first.artist == "Returned Artist" && first.album == "Returned Album" && first.duration == 245)
        precondition(first.spotifyTrackID == nil && first.isrc == nil)
        precondition(first.isSynchronized && first.lines.map(\.timestamp) == [1.2, 3.4])
        precondition(first.lines.allSatisfy { $0.timedSpans == nil && $0.translationText == nil })
        precondition(first.providerSourceID == "kugou:hash1:101")
        let requests = KugouFixtureProtocol.requests
        precondition(requests.count == 3 && requests.allSatisfy { $0.timeoutInterval > 0 && $0.timeoutInterval <= 4 })
        func query(_ request: URLRequest) -> [String: String] {
            Dictionary(uniqueKeysWithValues: URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value ?? "") })
        }
        precondition(query(requests[0])["keyword"] == "Query & Title Query Artist")
        precondition(query(requests[1])["hash"] == "hash1" && query(requests[1])["album_audio_id"] == "1")
        precondition(query(requests[2])["fmt"] == "lrc" && query(requests[2])["accesskey"] == "fixture-key&only")
        reset([catalog(4), lyricSearch(101), lyrics(), lyricSearch(102), lyrics(), lyricSearch(103), lyrics()])
        guard case .candidates(let capped) = await provider.lookup(track: track, identity: identity) else { fatalError("bounded candidates") }
        precondition(capped.count == 3 && KugouFixtureProtocol.requests.count == 7)
        for response in [json(["data": ["lists": []]]), json([:], status: 404)] {
            reset([response])
            guard case .noMatch = await provider.lookup(track: track, identity: identity) else { fatalError("empty catalog") }
        }
        reset([catalog(), json(["candidates": []])])
        guard case .noMatch = await provider.lookup(track: track, identity: identity) else { fatalError("no lyric body") }
        reset([catalog(2), lyricSearch(), json([:], status: 503), lyricSearch(102), lyrics()])
        guard case .candidates(let surviving) = await provider.lookup(track: track, identity: identity) else { fatalError("one failed chain must not hide another") }
        precondition(surviving.count == 1 && surviving[0].title == "Returned Title 2")
        for status in [401, 403, 500] {
            reset([json([:], status: status)])
            guard case .failed(.serverError(let actual)) = await provider.lookup(track: track, identity: identity) else { fatalError("HTTP error") }
            precondition(status == actual)
        }
        reset([json([:], status: 429)])
        guard case .failed(.rateLimited) = await provider.lookup(track: track, identity: identity) else { fatalError("rate limit") }
        for code: URLError.Code in [.timedOut, .cancelled, .notConnectedToInternet] {
            reset([.init(body: Data(), error: URLError(code))])
            guard case .failed(let failure) = await provider.lookup(track: track, identity: identity) else { fatalError("transport error") }
            precondition(failure == (code == .timedOut ? .timedOut : code == .cancelled ? .cancelled : .networkUnavailable))
        }
        for bad in [Data("{}".utf8), Data(repeating: 120, count: 1_048_577)] {
            reset([.init(body: bad)])
            guard case .failed(.parseFailure) = await provider.lookup(track: track, identity: identity) else { fatalError("invalid or oversized JSON") }
        }
        reset([catalog(), lyricSearch(), json(["content": "not base64!"])])
        guard case .failed(.parseFailure) = await provider.lookup(track: track, identity: identity) else { fatalError("invalid body") }
        reset([catalog(), lyricSearch(), lyrics("plain text without timings")])
        guard case .failed(.parseFailure) = await provider.lookup(track: track, identity: identity) else { fatalError("no fabricated LRC timing") }
        reset([])
        KugouFixtureProtocol.pending = true
        let task = Task { await provider.lookup(track: track, identity: identity) }
        try? await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()
        guard case .failed(.cancelled) = await task.value else { fatalError("active cancellation") }
        KugouFixtureProtocol.pending = false
        print("PASS: Kugou fixed-response LRC contract")
    }
}

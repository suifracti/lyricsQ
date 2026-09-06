import Foundation

// Live health evidence, 2026-09-06 (not repeated by this isolated contract):
// api.lyrics.ovh/v1/Coldplay/Yellow: HTTP 200, 1.26 s, 991 bytes,
// 41 nonempty lines; only "lyrics" returned. Nonsense artist/title: HTTP 404,
// 5.88 s, error-only JSON. 5 s connect / 12 s total timeout, no body logged.

// Mutation targets: automatic adoption, invented metadata/timing, unsafe path
// splitting, empty/error adoption, unbounded response consumption and cancellation.
private final class OVHFixtureProtocol: URLProtocol, @unchecked Sendable {
    static var status = 200
    static var body = Data()
    static var error: URLError?
    static var requests: [URLRequest] = []
    static var pending = false
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        if Self.pending { return }
        if let error = Self.error { client?.urlProtocol(self, didFailWithError: error); return }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct LyricsOVHContract {
    static func main() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OVHFixtureProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let provider = LyricsOVHProvider(session: session, timeout: 2)
        let track = Track(title: "A/B ?#%", artist: "Björk/Guest", album: "Unverified Album", duration: 300)
        let identity = TrackIdentity(track: track)
        func response(_ status: Int = 200, _ text: String = "{\"lyrics\":\"First line\\n\\n第二行\"}", error: URLError? = nil) {
            OVHFixtureProtocol.status = status
            OVHFixtureProtocol.body = Data(text.utf8)
            OVHFixtureProtocol.error = error
            OVHFixtureProtocol.requests = []
        }
        response()
        guard case .candidates(let candidates) = await provider.lookup(track: track, identity: identity), let candidate = candidates.first else { fatalError("plain lyrics must be manual candidates") }
        precondition(candidates.count == 1 && candidate.source == .lyricsOVH)
        precondition(candidate.title == track.title && candidate.artist == track.artist)
        precondition(candidate.album.isEmpty && candidate.duration == 0 && candidate.spotifyTrackID == nil && candidate.isrc == nil && candidate.language == nil)
        precondition(!candidate.isSynchronized && candidate.lines.map(\.originalText) == ["First line", "第二行"])
        precondition(candidate.lines.allSatisfy { $0.timestamp == 0 && $0.timedSpans == nil && $0.translationText == nil })
        let expectedPath = "Bj%C3%B6rk%2FGuest/A%2FB%20%3F%23%25"
        precondition(OVHFixtureProtocol.requests.count == 1)
        precondition(OVHFixtureProtocol.requests[0].url!.absoluteString == "https://api.lyrics.ovh/v1/" + expectedPath)
        precondition(OVHFixtureProtocol.requests[0].timeoutInterval == 2)
        precondition(candidate.providerSourceID == "lyricsOVH:" + expectedPath)
        response(404, "{\"error\":\"Not found\"}")
        guard case .noMatch = await provider.lookup(track: track, identity: identity) else { fatalError("404") }
        response(200, #"{"lyrics":" \n "}"#)
        guard case .noMatch = await provider.lookup(track: track, identity: identity) else { fatalError("empty") }
        for status in [401, 403, 500] {
            response(status)
            guard case .failed(.serverError(let actual)) = await provider.lookup(track: track, identity: identity) else { fatalError("HTTP failure is not no lyrics") }
            precondition(actual == status)
        }
        response(429)
        guard case .failed(.rateLimited) = await provider.lookup(track: track, identity: identity) else { fatalError("rate limit") }
        for code: URLError.Code in [.cancelled, .timedOut, .notConnectedToInternet] {
            response(error: URLError(code))
            guard case .failed(let failure) = await provider.lookup(track: track, identity: identity) else { fatalError("transport failure") }
            precondition(failure == (code == .cancelled ? .cancelled : code == .timedOut ? .timedOut : .networkUnavailable))
        }
        for body in ["not JSON", "{}", "{\"lyrics\":123}", "{\"lyrics\":\"" + String(repeating: "x", count: 1_048_577) + "\"}"] {
            response(200, body)
            guard case .failed(.parseFailure) = await provider.lookup(track: track, identity: identity) else { fatalError("invalid/oversized body") }
        }
        response()
        OVHFixtureProtocol.pending = true
        let pending = Task { await provider.lookup(track: track, identity: identity) }
        try? await Task.sleep(nanoseconds: 50_000_000)
        pending.cancel()
        guard case .failed(.cancelled) = await pending.value else { fatalError("in-flight cancellation") }
        OVHFixtureProtocol.pending = false
        print("PASS: lyrics.ovh fixed-response contract")
    }
}

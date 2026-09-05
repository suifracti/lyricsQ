import Foundation

@main
struct PianoSearchContract {
    static func main() async {
        let track = Track(title: "アーカイブ - Piano Ver.", artist: "stb", album: "アーカイブ", duration: 240, spotifyId: "5O45JO2bYhtyah2flZ9TI0")
        let identity = TrackIdentity(track: track)
        let metadata = TrackMetadata.bootstrap(from: track)
        let candidate = LyricsCandidate(id: "fixture", identity: identity, title: "アーカイブ", artist: "stb;NEA;ささ。", album: "アーカイブ", duration: 240, lines: [LyricLine(timestamp: 0, originalText: "Generated test line")], source: .qqExperimental, confidence: 0.87)
        if CommandLine.arguments.contains("live") {
            let result = await LyricsSearchManager(providers: [QQExperimentalLyricsProvider()]).lookup(track: track, identity: identity)
            guard case .candidates(let candidates) = result, !candidates.isEmpty else { fatalError("Live piano search should expose explicit candidates: \(result)") }
            print("LIVE candidates", candidates.map { "\($0.title)|\($0.artist)|\($0.lines.count) lines" })
            return
        }
        let decision = LyricsSafeMatcher.decide(candidate: candidate, metadata: metadata)
        print("Decision", decision.tier, decision.score, decision.reasons)
        precondition(decision.tier == .candidates, "Semicolon artist + arrangement title must yield selectable candidate, never automatic")
        precondition(decision.versionConflict)
        precondition(TrackTextNormalizer.extractVersionTags(fromTitle: "Piano Man").isEmpty)
        precondition(TrackTextNormalizer.stripVersionMarkers(fromTitle: "Piano Man") == "Piano Man")
        for title in ["アーカイブ - Piano Ver.", "アーカイブ (Piano Version)", "アーカイブ（ピアノ版）"] {
            precondition(TrackTextNormalizer.extractVersionTags(fromTitle: title).contains(.piano))
            precondition(TrackTextNormalizer.stripVersionMarkers(fromTitle: title) == "アーカイブ")
        }
        precondition(TrackTextNormalizer.artistTokens("stb;NEA;ささ。").primary == "stb")
        precondition(TrackTextNormalizer.artistTokens("HUNTR/X").primary == "HUNTR/X")
        precondition(LyricsQueryPlanner.plan(for: metadata).contains { $0.titleQuery == "アーカイブ" && $0.artistQuery == "stb" })
        let unrelated = LyricsCandidate(id: "unrelated", identity: identity, title: "アーカイブ", artist: "Other Artist;NEA", album: "アーカイブ", duration: 240, lines: candidate.lines, source: .qqExperimental, confidence: 0.9)
        precondition(LyricsSafeMatcher.decide(candidate: unrelated, metadata: metadata).tier == .reject)
        func copy(title: String = "アーカイブ", artist: String = "stb;NEA;ささ。", spotifyID: String? = nil, explanation: [String] = []) -> LyricsCandidate {
            LyricsCandidate(id: "copy", identity: identity, title: title, artist: artist, album: candidate.album, duration: candidate.duration, lines: candidate.lines, source: candidate.source, confidence: candidate.confidence, spotifyTrackID: spotifyID, matchExplanation: explanation)
        }
        precondition(LyricsSafeMatcher.decide(candidate: copy(spotifyID: "unrelated-recording"), metadata: metadata).tier == .reject)
        let exact = copy(title: track.title, artist: track.artist)
        let exactDecision = LyricsSafeMatcher.decide(candidate: exact, metadata: metadata)
        precondition(!exactDecision.versionConflict)
        precondition(exactDecision.tier == .autoHigh || exactDecision.tier == .autoMedium)
        precondition(copy(explanation: decision.explanation).arrangementNotice != nil)
        precondition(exact.arrangementNotice == nil)
        print("Piano search PASS")
    }
}

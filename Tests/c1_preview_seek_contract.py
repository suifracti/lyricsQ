"""Exercise the production preview identity guard with only a seek-I/O spy."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
state_source = (root / 'SpotifyLyrics/Services/PlaybackState.swift').read_text()

def block(signature, text):
    start = text.index(signature)
    opening = text.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]

identity_property = block('public var canSeekDisplayedLyrics: Bool', state_source)
seek_method = block('public func seekFromDisplayedLyrics(', state_source)
identity_property = identity_property.replace('public var', 'var', 1)
seek_method = seek_method.replace('public func', 'func', 1)

program = '''import Foundation

final class PreviewGuardProbe {
    let isShowingSearchPreview: Bool
    let displayedTrack: Track
    let liveTrackIdentity: TrackIdentity?
    var seeks: [Double] = []

    init(isPreview: Bool, displayedTrack: Track, liveTrack: Track?) {
        self.isShowingSearchPreview = isPreview
        self.displayedTrack = displayedTrack
        self.liveTrackIdentity = liveTrack.map(TrackIdentity.init(track:))
    }

IDENTITY

    func seek(to position: TimeInterval, source: String) {
        seeks.append(position)
    }

SEEK
}

let liveA = Track(id: "a", title: "A", artist: "artist", album: "album", duration: 180, spotifyId: "spotify-a")
let previewB = Track(id: "b", title: "B", artist: "artist", album: "album", duration: 180, spotifyId: "spotify-b")

let crossIdentity = PreviewGuardProbe(isPreview: true, displayedTrack: previewB, liveTrack: liveA)
precondition(!crossIdentity.canSeekDisplayedLyrics, "preview B must not be allowed to control live A")
precondition(!crossIdentity.seekFromDisplayedLyrics(to: 42, source: "preview-row"))
precondition(crossIdentity.seeks.isEmpty, "cross-identity preview click must not call seek")

let sameIdentity = PreviewGuardProbe(isPreview: true, displayedTrack: liveA, liveTrack: liveA)
precondition(sameIdentity.canSeekDisplayedLyrics)
precondition(sameIdentity.seekFromDisplayedLyrics(to: 42, source: "same-live-row"))
precondition(sameIdentity.seeks == [42], "same live identity retains lyric-row seeking")

let liveLyrics = PreviewGuardProbe(isPreview: false, displayedTrack: liveA, liveTrack: liveA)
precondition(liveLyrics.seekFromDisplayedLyrics(to: 18, source: "live-row"))
precondition(liveLyrics.seeks == [18])

let noLiveTrack = PreviewGuardProbe(isPreview: true, displayedTrack: previewB, liveTrack: nil)
precondition(!noLiveTrack.canSeekDisplayedLyrics)
precondition(noLiveTrack.seeks.isEmpty)
print("C1 preview identity guard: PASS (cross identity blocked, same identity/live allowed)")
'''.replace('IDENTITY', identity_property).replace('SEEK', seek_method)

with tempfile.TemporaryDirectory(prefix='spotifylyrics-c1-preview-') as temp:
    script = Path(temp) / 'main.swift'
    script.write_text(program)
    binary = Path(temp) / 'contract'
    subprocess.run([
        'swiftc',
        str(root / 'SpotifyLyrics/Models/Models.swift'),
        str(root / 'SpotifyLyrics/Lyrics/TrackIdentity.swift'),
        str(script), '-o', str(binary)
    ], check=True)
    subprocess.run([str(binary)], check=True)

v3_source = (root / 'SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift').read_text()
canvas_source = (root / 'SpotifyLyrics/Views/Components/LyricsCanvasView.swift').read_text()
assert re.search(
    r'state\.seekFromDisplayedLyrics\(\s*to: timestamp,\s*source: "v3-lyric-line"',
    v3_source
)
assert re.search(
    r'state\.seekFromDisplayedLyrics\(\s*to: seekTimestamp,\s*source: "lyric-line"',
    canvas_source
)
print('C1 lyric-row guard wiring: PASS (V3 and shared Classic canvas)')

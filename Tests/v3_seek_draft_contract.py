"""Exercise the real V3 slider callbacks without a window or Spotify process."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift').read_text()
source = source.split('private struct AppleMusicImmersiveV3PlaybackProgress: View {', 1)[1]
source = source.split('private struct AppleMusicImmersiveV3TransportControls:', 1)[0]

def block(signature, text=source):
    start = text.index(signature)
    opening = text.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end].replace('private ', '')

fields = '\n'.join(re.findall(r'@State private (var (?:isEditing|draftPosition)[^\n]*)', source))
setter = re.search(r'set: \{ (draftPosition = [^\n]+) \}', source).group(1).replace('$0', 'value')
probe = '''import Foundation
final class FakePlaybackState {
    var currentTime: Double = 18
    var seeks: [Double] = []
    func seek(to value: Double, source: String) { seeks.append(value) }
}
final class ProgressProbe {
    let state = FakePlaybackState()
    var interactionChanged: (Bool) -> Void = { _ in }
    let duration: Double = 240
FIELDS
    func write(_ value: Double) { SETTER }
VISIBLE
EDITING
}
let valueFirst = ProgressProbe()
valueFirst.write(120)
precondition(valueFirst.visiblePosition == 120, "A click target must become visible before begin-edit arrives")
valueFirst.handleEditingChanged(true)
valueFirst.handleEditingChanged(false)
precondition(valueFirst.state.seeks == [120], "Begin-edit must not replace the click target with old playback position")
valueFirst.handleEditingChanged(false)
precondition(valueFirst.state.seeks == [120], "Duplicate editing-end must not send another seek")
let beginFirst = ProgressProbe()
beginFirst.handleEditingChanged(true)
beginFirst.write(120)
beginFirst.state.currentTime = 19
precondition(beginFirst.visiblePosition == 120, "Live refresh must not overwrite a drag target")
beginFirst.handleEditingChanged(false)
precondition(beginFirst.state.seeks == [120])
let unchanged = ProgressProbe()
unchanged.handleEditingChanged(true)
unchanged.handleEditingChanged(false)
precondition(unchanged.state.seeks.isEmpty, "A tracking callback without a value change must not seek")
let clamped = ProgressProbe()
clamped.write(400)
clamped.handleEditingChanged(false)
precondition(clamped.state.seeks == [240])
precondition(clamped.visiblePosition == 18, "An ended draft must release the display to live playback")
print("V3 seek draft contract: PASS (both callback orders, tracking without a value, duplicate end, refresh, clamp)")
'''
probe = probe.replace('FIELDS', fields).replace('SETTER', setter).replace('VISIBLE', block('private var visiblePosition: Double')).replace('EDITING', block('private func handleEditingChanged'))
with tempfile.TemporaryDirectory(prefix='lyrics-v3-seek-draft-') as temp:
    script = Path(temp) / 'main.swift'
    script.write_text(probe)
    binary = Path(temp) / 'contract'
    subprocess.run(['swiftc', str(script), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)

fullscreen = (root / 'SpotifyLyrics/Views/Fullscreen/FullScreenLyricsView.swift').read_text()
full_method = block('private func seekEditingChanged', fullscreen)
full_binding = block('private var seekBinding', fullscreen)
full_setter = re.search(r'set: \{ ([^\n]+) \}', full_binding).group(1).replace('$0', 'value')
full_probe = """import Foundation
struct FakeTrack { var duration: Double = 240 }
final class FakeState {
    var currentTime: Double = 18
    var currentTrack = FakeTrack()
    var seeks: [Double] = []
    func seek(to value: Double, source: String) { seeks.append(value) }
}
final class FullscreenProbe {
    let state = FakeState()
    var draftSeekTime: Double?
    func write(_ value: Double) { SETTER }
METHOD
}
let click = FullscreenProbe()
click.write(120)
click.seekEditingChanged(true)
click.seekEditingChanged(false)
precondition(click.state.seeks == [120], "Fullscreen begin-edit must preserve an already-written click target")
click.seekEditingChanged(false)
precondition(click.state.seeks == [120])
let drag = FullscreenProbe()
drag.seekEditingChanged(true)
drag.write(120)
drag.state.currentTime = 19
drag.seekEditingChanged(false)
precondition(drag.state.seeks == [120])
let unchanged = FullscreenProbe()
unchanged.seekEditingChanged(true)
unchanged.seekEditingChanged(false)
precondition(unchanged.state.seeks.isEmpty)
print("Fullscreen seek draft contract: PASS")
""".replace('SETTER', full_setter).replace('METHOD', full_method)
with tempfile.TemporaryDirectory(prefix='lyrics-fullscreen-seek-draft-') as temp:
    script = Path(temp) / 'main.swift'
    script.write_text(full_probe)
    binary = Path(temp) / 'contract'
    subprocess.run(['swiftc', str(script), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)

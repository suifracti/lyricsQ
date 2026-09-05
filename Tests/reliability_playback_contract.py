"""Compile verbatim PlaybackState methods with real session/repository dependencies.
The host omits app startup, Spotify, timers and user preferences. No copied method bodies.
"""
from pathlib import Path
import re, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'SpotifyLyrics/Services/PlaybackState.swift').read_text()
def method(signature):
    start = source.index(signature)
    opening = source.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]
methods = '\n'.join(method(s) for s in ['public func adoptLyricsCandidate(', 'public func refreshListeningHistory()', 'public func refreshListeningStatistics(', 'private static func mergeHistoryEntries('])
# Read production load-state fields as well as methods; replace only Combine/access-control syntax.
host = '''import Foundation
@MainActor final class PlaybackSlice {
 let lyricsRepository: SQLiteLyricsRepository
 let lyricsSession = LyricsSessionController(providers: [])
 let searchPreviewSession = LyricsSessionController(providers: [])
 var searchPreviewTrack: Track?
 init(repository: SQLiteLyricsRepository) { lyricsRepository = repository }
'''
field_names = ['var listeningHistory:', 'var listeningStatistics:', 'var isListeningHistoryLoading',
               'var isListeningStatisticsLoading', 'var listeningHistoryError', 'var listeningStatisticsError']
host += '\n'.join(
    line.replace('@Published public private(set) ', '')
    for line in source.splitlines()
    if '@Published public private(set)' in line and any(name in line for name in field_names)
)
host += '\n var listeningHistoryLoadTask: Task<Void, Never>?\n var listeningStatisticsLoadTask: Task<Void, Never>?\n'
host += methods + '\n}\n'
sources = re.findall(r'^  (SpotifyLyrics/[^ \n]+\.swift) ', (ROOT / 'Tests/listening_statistics_contract.sh').read_text(), re.M)
with tempfile.TemporaryDirectory(prefix='lyrics-reliability-slice-') as tmp:
    p = Path(tmp)
    (p/'PlaybackSlice.swift').write_text(host)
    binary = p/'contract'
    subprocess.run(['swiftc','-parse-as-library',*[str(ROOT/s) for s in sources],str(p/'PlaybackSlice.swift'),str(ROOT/'Tests/reliability_playback_contract.swift'),'-o',str(binary)],check=True)
    print('Source base:',subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),flush=True)
    subprocess.run([str(binary)],check=True)

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/spotifylyrics-a0-contract.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

PLAYBACK="$ROOT/SpotifyLyrics/Providers/PlaybackProvider.swift"
SPOTIFY="$ROOT/SpotifyLyrics/Providers/SpotifyDesktopProvider.swift"
MUSIC="$ROOT/SpotifyLyrics/Providers/AppleMusicDesktopProvider.swift"
MOCK="$ROOT/SpotifyLyrics/Providers/MockPlaybackProvider.swift"
STATE="$ROOT/SpotifyLyrics/Services/PlaybackState.swift"
JOB="$ROOT/SpotifyLyrics/Capture/AutomaticAlignmentJobController.swift"
COORD="$ROOT/SpotifyLyrics/Capture/LiveCaptureCoordinator.swift"
SPIKE="$ROOT/SpotifyLyrics/Capture/SpotifyScreenCaptureAudioSpike.swift"
MAIN="$ROOT/SpotifyLyrics/Main.swift"
SETTINGS="$ROOT/SpotifyLyrics/Settings/AppSettingsStore.swift"
LOCAL="$ROOT/SpotifyLyrics/Services/PlaybackState.swift"
CONTRACT="$ROOT/Tests/a0_capture_source_containment_contract.swift"

for file in "$PLAYBACK" "$SPOTIFY" "$MUSIC" "$MOCK" "$STATE" "$JOB" "$COORD" "$SPIKE" "$MAIN" "$SETTINGS" "$CONTRACT"; do
    test -f "$file"
done

# Runtime evidence uses the production source gate and production stale guard;
# the only fake I/O is the capture/discovery/adopt counter in the contract.
swiftc -parse-as-library "$PLAYBACK" "$CONTRACT" -o "$TMP_DIR/a0-capture-source"
"$TMP_DIR/a0-capture-source"

# Provider snapshots carry source provenance from the actual provider, rather
# than deriving it from process existence, title, or a Spotify track ID.
grep -Eq 'enum PlaybackSourceIdentity' "$PLAYBACK"
grep -Eq 'sourceIdentity: PlaybackSourceIdentity' "$PLAYBACK"
grep -Eq 'sourceIdentity: \.spotifyDesktop' "$SPOTIFY"
grep -Eq 'sourceIdentity: \.appleMusic' "$MUSIC"
grep -Eq 'sourceIdentity: \.mockPreview' "$MOCK"

# Product source gate and explicit unsupported-source diagnostics.
grep -Eq 'playbackSourceIdentity' "$STATE"
grep -Eq 'liveCaptureEligibility\(' "$STATE" "$JOB" "$COORD" "$SPIKE"
grep -Eq 'notifyPlaybackSourceChanged' "$STATE" "$JOB"
grep -Eq 'AutomaticLiveCaptureSessionGuard' "$JOB" "$PLAYBACK"
grep -Eq 'guard accepts\(sessionGuard, playback: playback\)' "$JOB"
grep -Eq '当前 Apple Music 播放不支持 Spotify live capture' "$COORD" "$SPIKE"

# The low-level Spotify discovery call is downstream of the source gate.
python3 - "$COORD" "$SPIKE" <<'PY'
from pathlib import Path
import sys

coord = Path(sys.argv[1]).read_text()
spike = Path(sys.argv[2]).read_text()
coord_gate = coord.index("let eligibility = playback.liveCaptureEligibility(requiresPlaying: false)")
coord_guard = coord.index("let startGuard", coord_gate)
coord_observers = coord.index("installPlaybackObservers()", coord_guard)
coord_start = coord.index("SpotifyScreenCaptureAudioSpike.shared.start", coord_gate)
if coord_gate > coord_start:
    raise SystemExit("coordinator capture start must follow source gate")
if not coord_guard < coord_observers < coord_start:
    raise SystemExit("coordinator must install startup provenance before async capture")
coord_recheck = coord.index("accepts(startGuard, playback: playback)", coord_start)
if coord_start > coord_recheck:
    raise SystemExit("coordinator must recheck startup provenance after async capture")
spike_gate = spike.index("let eligibility = playback.liveCaptureEligibility(requiresPlaying: false)")
spike_guard = spike.index("activeCaptureGuard", spike_gate)
spike_discovery = spike.index("discoverSpotifyApplications", spike_gate)
if spike_gate > spike_discovery:
    raise SystemExit("spike discovery must follow source gate")
spike_recheck = spike.index("accepts(startGuard", spike_guard)
if spike_guard > spike_recheck:
    raise SystemExit("spike must recheck its active provenance after async startup")
PY

# Mid-job source/track/generation invalidation and final adopt recheck.
grep -Eq 'lastPlaybackSource|evaluatePlaybackContextChange' "$COORD"
grep -Eq 'alignmentGeneration|generationFlag' "$COORD"
grep -Eq 'source_or_identity|playbackSourceIdentity == \.spotifyDesktop' "$COORD"
grep -Eq 'case starting|pendingStartRequestID|startGuard' "$COORD"
grep -Eq 'activeCaptureGuard|accepts\(startGuard' "$SPIKE" "$COORD"
grep -Eq 'guard accepts\(sessionGuard, playback: playback\)' "$JOB"
grep -Eq 'saveAlignedVersion' "$JOB"
grep -Eq 'Task\.isCancelled|accepts\(sessionGuard, playback: playback\)' "$JOB"

# Local-file alignment remains a separate path and does not enter live capture.
python3 - "$LOCAL" <<'PY'
from pathlib import Path
text = Path(__import__("sys").argv[1]).read_text()
start = text.index("public func alignCurrentLyricsWithLocalAudio()")
end = text.index("private func confirmAlignmentAudioMetadata", start)
chunk = text[start:end]
if "LiveCaptureCoordinator" in chunk or "SpotifyScreenCaptureAudioSpike" in chunk:
    raise SystemExit("local audio alignment must remain independent of live capture")
PY

# The automatic product switch remains opt-in; debug-only menus remain debug
# reachability, while the automatic controller itself is Release-compiled.
grep -Eq 'automaticAlignmentEnabled = defaults\.object\(forKey: Key\.automaticAlignmentEnabled\) as\? Bool \?\? false' "$SETTINGS"
first_nonempty_job=$(grep -vE '^\s*$|^\s*//' "$JOB" | sed -n '1p')
test "$first_nonempty_job" != "#if DEBUG"
grep -Eq '#if DEBUG' "$MAIN"
grep -Eq '排轴捕获 Spike（调试）' "$MAIN"

echo "a0_capture_source_containment_contract: PASS"

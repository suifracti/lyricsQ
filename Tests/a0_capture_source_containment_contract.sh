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

# A late ScreenCaptureKit callback must carry immutable stream/session
# provenance through both the synchronous WAV writer path and the MainActor
# continuity path. The automatic product path must also own the coordinator
# generation it waits for; a busy coordinator cannot donate an older handoff.
grep -Eq 'audioSampleHandler: \(\(CMSampleBuffer, UInt64\) -> Void\)\?' "$SPIKE"
grep -Eq 'sampleGenerationFlag|sampleDeliveryGeneration' "$COORD"
grep -Eq 'sampleGeneration' "$COORD"
grep -Eq 'setSampleDeliveryGeneration|sampleDeliveryGate|activeStreamID' "$SPIKE"
python3 - "$JOB" "$SPIKE" <<'PY'
from pathlib import Path
import sys

job = Path(sys.argv[1]).read_text()
spike = Path(sys.argv[2]).read_text()
before = job.index("await coordinator.start(")
started = job.index("let startedGeneration = coordinator.lastStartedGeneration", before)
if "let generationBeforeStart = coordinator.lastStartedGeneration" not in job[before - 600:before]:
    raise SystemExit("automatic capture must snapshot coordinator generation before start")
if not (before < started):
    raise SystemExit("automatic capture must read its started generation after start")
handoff = job.index("let handoff = coordinator.lastAlignmentHandoff", started)
if "handoff.generation == startedGeneration" not in job[started:handoff + 500]:
    raise SystemExit("automatic capture must require a generation-matched handoff")
report_guard = job.index("guard let report", handoff)
if "handoff?.report ?? LiveCaptureCoordinator.shared.lastPartialReport" in job[report_guard:report_guard + 180]:
    raise SystemExit("automatic capture must not fall back to an unowned lastPartialReport")

append_start = Path("SpotifyLyrics/Capture/LiveCaptureCoordinator.swift").read_text().index(
    "private func appendPCM("
)
coordinator = Path("SpotifyLyrics/Capture/LiveCaptureCoordinator.swift").read_text()
append_guard = coordinator.index("guard sampleGenerationFlag.matches", append_start)
append_write = coordinator.index("openSegment?.wavWriter?.append", append_start)
if not append_guard < append_write:
    raise SystemExit("WAV writer must validate sample generation before append")
ingest_start = coordinator.index("private func ingestOnMain(")
ingest_guard = coordinator.index("guard sampleGenerationFlag.matches", ingest_start)
ingest_state = coordinator.index("guard state == .running", ingest_start)
if not ingest_guard < ingest_state:
    raise SystemExit("MainActor sample ingestion must validate sample generation first")

env = spike.index('ProcessInfo.processInfo.environment["SPOTIFYLYRICS_SCK_SPIKE"]')
debug = spike.rfind("#if DEBUG", 0, env)
if debug < 0:
    raise SystemExit("direct spike environment auto-start must be DEBUG-only")
PY

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

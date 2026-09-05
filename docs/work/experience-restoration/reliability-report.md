# Reliability repair — Task 1

Worktree `/private/tmp/spotifylyrics-experience-restoration-20260905`, branch `codex/experience-restoration`, base HEAD `b971c7fe181315f8f8ad5a784a7b8ba14bce24fe` plus uncommitted changes. HEAD matched upstream at inspection. The primary user checkout was not modified. No commit/push by this task; root owns integration/review.

## Changes

- `PlaybackState.adoptLyricsCandidate` selects the presented preview session when a preview track exists; otherwise live. Session identity rejection is unchanged.
- Menu bar controller accepts a native settings handler, bound from MainLyricsWindowView's SwiftUI `openSettings` environment. The other settings callback in that view also uses the environment action.
- History and all statistics row loops now throw unless SQLite reports ROW/DONE; the statistics aggregate also verifies DONE after its single row. No schema/statistics definition changes.
- History/statistics publish loading and error state, preserve the last successful data on refresh/failure, and clear errors after retry. Views show progress and explicit retry. Statistics retained from a different range are labelled with the actual range, rather than relabelled as the requested range. Cold failure does not display a fabricated empty success.
- Restored history/session shell source manifests. Relevant SQLite tests now explicitly direct alignment provenance into their temporary fixture directory as well as using temporary databases.

## Regression evidence

Tests execute production code, not source-text predicates. `reliability_playback_contract.py` extracts the current production methods and load-state declarations verbatim into a minimal host, compiles with the real LyricsSessionController and SQLiteLyricsRepository, and omits unrelated app startup/Spotify/preferences. It is a method integration test, not a claim of full app lifecycle coverage. The native Settings host compiles the entire production menu bar controller; its playback/popover stubs only exclude unrelated startup and rendering.

Red failures were observed before each relevant fix:

- History lock returned empty success: `reliability-history-red.log`.
- Preview B candidate failed to enter preview: `reliability-playback-red.log`.
- After candidate fix, statistics failure discarded last good value: `reliability-load-red.log`.
- Real native Settings scene failed to open through the selector route: `reliability-settings-red.log`.

Local ignored evidence logs are in `reliability-evidence/`; the tracked build summary and reproducible contracts are retained in Git. The Swift assertion failures are expected TDD red runs, not current failures.

Validation commands from the worktree:

| Command | Result |
| --- | --- |
| `bash Tests/listening_history_contract.sh` | PASS; temporary exclusive lock throws, rollback/retry returns both saved records, statistics recover |
| `bash Tests/sqlite_session_contract.sh` | PASS; original session assertions now actually compile/run |
| `python3 Tests/reliability_playback_contract.py` | PASS; preview/live routing, identity protection, retained values, cold failure, failed range switch and successful retry against real temporary SQLite |
| `bash Tests/settings_route_contract.sh` | PASS; actual Settings window first open, repeated open, close main and settings then reopen |
| `bash Tests/listening_statistics_contract.sh` | PASS; normal statistics, daily counts and empty fixture |
| `git diff --check` | PASS |
| Debug xcodebuild below | BUILD SUCCEEDED, exit 0; existing warnings, no errors |

```sh
xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics \
  -configuration Debug -derivedDataPath /tmp/lyrics-reliability-restoration-deriveddata \
  CODE_SIGNING_ALLOWED=NO build
```

Full build log: `/tmp/reliability-debug-build.log`. Shared worktree contained concurrent presentation edits during the build; root must perform final integration builds after all edits settle. One statistics compile was interrupted by this task's fixture-path edit, then rerun; this was not a product test failure.

## Owned paths for root staging/review

- SpotifyLyrics/Persistence/SQLiteLyricsRepository.swift
- SpotifyLyrics/Services/PlaybackState.swift
- SpotifyLyrics/Windows/MenuBarLyricsController.swift
- SpotifyLyrics/Views/MainWindow/MainLyricsWindowView.swift
- SpotifyLyrics/Views/Settings/ListeningHistoryView.swift
- SpotifyLyrics/Views/Settings/ListeningStatisticsView.swift
- Tests/listening_history_contract.sh and .swift
- Tests/listening_statistics_contract.swift
- Tests/sqlite_session_contract.sh and .swift
- Tests/reliability_playback_contract.py and .swift
- Tests/settings_route_contract.sh
- Tests/fixtures/settings_playback_stub.swift
- Tests/fixtures/settings_route_host.swift
- docs/work/experience-restoration/reliability-report.md and reliability-evidence/

No real Spotify controls, user app database, release artifact, schema migration policy, or downgraded save-callback finding was exercised/modified. Root retains full application visual/integration acceptance and release build responsibility.

## Independent integration review

Root-appointed independent reviewer found no actionable defects and independently reran all five focused suites successfully. Root full-production Debug build passed with `/tmp/lyrics-experience-integration-deriveddata`; final visual changes will receive another integrated build.

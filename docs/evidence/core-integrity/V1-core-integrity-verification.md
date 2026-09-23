# V1 — M1 Core Integrity Verification

- Status: `IN_PROGRESS`
- Candidate base: U1 final `d75789ee74b1a68c6caf02cd062b14b3c59dcd24`
- Branch: `codex/v1-core-integrity-verification`
- Worktree: `/private/tmp/spotifylyrics-v1-core-integrity-verification`
- U1 production source through `a33e9a160a413f928429fa976fc071f5e3f5fe27` is an ancestor; H1/T1/T2/S1/O1/R1 are also ancestors.
- No production source changes are planned. V1 may update focused test expectations only where current production behavior and authoritative decisions prove the old assertion stale.

## Baseline and safeguards

The worktree was created from the supplied U1 final SHA. The formal root remains at its older H1 checkout and is not used for V1 edits. The U1 worktree and its pushed branch remain untouched. The three pre-existing `PROJECT_FULL_AUDIT_*.md` reports remain outside this worktree and are not staged.

Automated work uses existing focused contracts and their temporary fixtures. The app, formal user database, live player, audio capture, AI, and credentials are outside this verification. UI smoke will run only if an existing harness proves all of its storage and connection boundaries isolated.

## Verification plan

Recheck the B0–U1 batch evidence against this candidate rather than treating historical passes as current passes. Reproduce and classify the two U1 runner failures before making any test-only correction. Run a small, explicit core-contract selection, a task-specific `/tmp` Debug build, and record any skipped human/UI validation separately. Final result and matrix will be added after evidence collection.

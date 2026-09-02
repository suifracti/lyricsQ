# AI Handoff Rules

## Project boundary

The only formal project root is:

`/Users/apple/backup/sptifylyrics`

The checked-out Git working tree is the source of truth. When the worktree is clean, `HEAD` is the exact source version. When it is dirty, report the base `HEAD` plus the uncommitted changes; never call an older backup or build product the latest source.

`main` is the confirmed baseline and the default starting point for new work. Normally create a task branch from `main`.

## Sources of truth

The authoritative hierarchy for current work is:

1. 用户明确指令
2. Obsidian Current 的 Spotify Lyrics `README.md`、`Decisions.md`、活动 `Handoff.md`
3. Git `HEAD` 与真实运行证据

Craft 已弃用，不得用于当前方向、优先级、阶段或项目状态判断。历史上的 Craft 页面与旧 execution board 仅保留为归档材料，不具备当前权威。

- Git `HEAD` is authoritative for the exact source version.
- `docs/archive/` and old reports are historical evidence only; they must not override the current authoritative sources above.
- `.local/` is never a source tree. Its `backups/`, `patches/`, `reference-projects/`, and `builds/` contain local history or reference material only. Do not automatically restore or overwrite source from `.local/`.

## Before starting work

At minimum, inspect:

```sh
git status
git branch --show-current
git rev-parse HEAD
git log -5 --oneline
```

Also inspect the user instructions and Obsidian Current's Spotify Lyrics documents (`README.md`, `Decisions.md`, and any active `Handoff.md`) before deciding the product scope. Craft 已弃用，不得依据旧 Craft execution board 进行决策。 For a substantial change, create a reversible checkpoint commit and push it before proceeding.

## Prohibited without explicit authorization

- `git reset --hard`
- `git clean`
- `git restore` when it would overwrite current changes
- force push
- rebase or other history rewriting
- inferring the latest version from an old branch, DerivedData directory, old `.app`, backup, or file modification time
- running `generate_xcodeproj.py`

Do not discard user changes or switch to a historical version to satisfy an old report.

See [`docs/DEVELOPMENT_WORKFLOW.md`](docs/DEVELOPMENT_WORKFLOW.md) for build, archive, branch, commit, and release rules.
Before staging, committing, or pushing, follow [`docs/SUBMISSION_BASELINE.md`](docs/SUBMISSION_BASELINE.md).

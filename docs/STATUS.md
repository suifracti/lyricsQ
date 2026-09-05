# Project Status

Status snapshot: 2026-09-05.

This file describes what is present in the repository and how mature it is. It is not a release promise. The authoritative hierarchy is: (1) 用户明确指令, (2) Obsidian Current 的 Spotify Lyrics `README.md`、`Decisions.md`、活动 `Handoff.md`, (3) Git `HEAD` 与真实运行证据. Craft 已弃用，不得用于当前方向、优先级、阶段或项目状态判断. Git identifies the exact source.

## Canonical engineering SOT baseline

- **Canonical engineering SOT**: fresh remote `origin/main`
- **Latest product-code-changing merge**: `b16caee38eb4bb1d02d30c2971437d39ed59eb93` (C5)
- **Status-convergence docs-only merge**: `54ab96226fb62064e6dad7f6d888dc47cdbd28b9` (PR #20)
- Other Windows C1–C5 全部完成并合入主线，状态均为 `CLOSED / FROZEN / MERGED`:
  - **C1**: 独立歌词库窗口（PR #15）
  - **C2**: 独立最近播放窗口（PR #16）
  - **C3**: 统一“歌词库与收听记录”工具窗口与路由（PR #17）
  - **C4**: 听歌统计完善（PR #18：3张统计卡片、7天每日观察播放趋势柱状图、Top 5 歌曲/歌手收敛）
  - **C5**: MenuBar Quick Glance / Transport 补齐（PR #19：封面、原生三键、主窗口/歌词库/设置/退出4项入口）

## Released internal builds

- `v0.1.0`: 源提交 `910df5dc55e44a19144be0b6ccf79a3145a67943`
- `v0.1.1`: 源提交 `9e65fbbe13b82626bfb5d9bc36f2620a44dd2762`
- **版本边界明确**:
  - `v0.1.1` 属于 internal/test prerelease，包含 C3。
  - **不包含后续完成的 C4 与 C5**。
  - 不是当前 `main` 的完整体验包。
  - 已发布的 `v0.1.1` 保持冻结，不覆盖、不重新打 tag 或重新发布。

## Dirty checkout warning

- 本地主目录 `/Users/apple/backup/sptifylyrics` **不是 canonical main**。
- 该目录包含用户未提交的资产与本地工具脚本。
- **严禁**执行 `git reset --hard`、`git clean`、`git restore`、`git pull` 或分支检出覆盖。
- 所有后续新任务必须从 fresh `origin/main` 建立全新的 isolated worktree。

## Current phase & next steps

- 用户于 2026-09-05 明确授权修复可靠性问题，恢复灵动岛、完善桌面歌词和三种封面风格，并自主迭代。该范围重新开放；历史 C1–C5 合并记录与冻结 release 不改写。
- 工作分支 `codex/experience-restoration`，从 `fb95a9e` 建立；未合入 main。
- 预览候选采用路由、菜单栏设置入口、历史/统计读取错误表达已修复；五项定向合同与独立审查通过。实际 SQLite 锁读取失败会报错，界面保留上次结果并支持重试。
- 灵动岛、桌面歌词和三种风格仍在原生视觉与交互验证中；不标记为最终体验验收或已发布。
- statistics contract 午夜日期夹具稳定性仍为既有 Deferred。

## Implemented in the repository

- Spotify Desktop current-track observation and basic playback commands.
- Main, floating, fullscreen, and capsule lyrics presentations.
- MenuBar Quick Glance / Transport popover (AppKit `NSStatusItem` + `NSPopover`).
- Unified "歌词库与收听记录" window with tabs for 我的歌词库, 最近播放, and 听歌统计.
- Synchronized lyrics rendering, progress tracking, search/recovery states, and presentation settings.
- Local LRC/TXT import and paste, a lyrics editor, versioned SQLite persistence, and local-file lookup.
- LRCLIB lookup plus experimental NetEase and QQ provider implementations.
- Japanese reading/ruby generation, romanization and translation companion-layer infrastructure, including local correction data.
- Optional Spotify Web Catalog integration with credentials stored outside the repository.
- Focused shell/Swift contract tests for major UI, persistence, provider, reading, and alignment boundaries.

## How to verify the current truth

```sh
git status
git branch --show-current
git rev-parse HEAD
git log -5 --oneline
git rev-parse '@{upstream}'
```

If the worktree is dirty, describe the version as `base HEAD + uncommitted changes`. Do not infer freshness from `.app` files, DerivedData, `.local/`, screenshots, backups, or modification times.

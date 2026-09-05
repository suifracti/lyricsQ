# Project Status

Status snapshot: 2026-09-05.

Library preview: per-version local names and notes can be edited for lyrics, translations, readings and timing. Original labels remain visible; Restore Default clears only local presentation metadata. Metadata does not travel in asset exports.

Production database upgrade repaired: existing v5 databases now advance to v8 after a consistent backup; library/history/statistics verified against the real database and after restart. See [upgrade audit](work/experience-restoration/production-database-upgrade-report.md).

Main V3 utility shortcuts: 我的歌词库、最近播放、听歌统计 now have direct toolbar buttons, using the existing shared library window and selecting its matching tab. Existing Settings entries remain available.

Main V3 preview update: long original lyrics now use measured balanced wrapping, replacing the earlier approximate character-count breaker. Screenshot phrases pass five width checks; plain/timed ranges agree. Inline ruby remains separate. See [balanced lyric breaks report](work/experience-restoration/balanced-lyric-breaks-report.md).

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
- 灵动岛已恢复为默认，桌面歌词采用独立的大字描边/单双行/配色方案，三种风格完成原生迭代；用户进一步确认封面必须完整：舞台保留原图居中等比适配、不裁切，采用镜像边缘延展并向外柔化；窗口自由缩放，禁止锁比例或自动改尺寸，歌词布局暂不调整。定向测试、独立复核及生产 Debug/Release 构建通过；作为独立预览交付，未合入 main 或发布新版本。
- 原生生成夹具验证包括封面比例、桌面明暗背景与最小布局、逐字时间高亮和灵动岛更多菜单。物理刘海屏、多屏切换、系统 Reduce Motion 与长期真实 Spotify 播放未作最终实机验收。
- 标题/手动歌词恢复已修复：保留无艺人搜索、LRCLIB 全文查询和候选展示；真实 Marigold 查询可返回 Aimyon 候选，自动跨艺人保护保留。专项检查及 Debug/Release 通过，新预览已打开；Marigold 原生选词待再次播放确认。旧 real_track 综合脚本存在依赖缺失，未通过。详见 `docs/work/experience-restoration/title-only-recovery-report.md`。
- V3 右上角工具栏收敛为窗口、搜索、更多三个入口；更多中保留歌词操作、外观、设置和来源恢复；窗口仍自由缩放。新增悬停保持显示，弹出面板保持可见。
- 主窗口长歌词保持字号并按阅读宽度换行；翻译、假名和罗马音移除两行截断。复用现有 CoreText/SwiftUI 排版与逐字时间映射，不拆分歌词记录。
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

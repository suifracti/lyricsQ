# Spotify Lyrics Current Status

状态页最后更新：2026-09-22。
这是 repository 的唯一滚动工程状态入口；详细运行证据保留在 `docs/evidence/`，不在本页复制完整审计。

文档链：`README.md` → `docs/STATUS.md` → 具体 evidence / batch report / 已授权计划。

## Source Identity

- repo root：`/Users/apple/backup/sptifylyrics`
- branch：`main`
- source HEAD（B0 / v0.1.2 产品基线）：`6528be3103f75fd4f63757855b9d61cd30f757d8`
- release identity：正式 GitHub Release `v0.1.2`，release commit 同上
- status last updated：`2026-09-22`
- tracked/staged 状态：D0 只产生文档与 B0 evidence 变更，`SpotifyLyrics/` 生产源码 diff 为零；三份既有 `PROJECT_FULL_AUDIT_*.md` 保持 untracked，不纳入本状态页或 D0 提交。精确 checkout 仍以 `git rev-parse HEAD` 为准。

## Product Boundary

- **Core**：V3 / Fullscreen
- **Supported Secondary**：Desktop transparent v2 / Menu Bar
- **Experimental**：Direction D / Capsule
- **Legacy**：Classic V1 / desktop legacy panel
- **iOS**：当前无 iOS target

这里的分类表示维护级别和工程边界：Experimental 不是不可达，Legacy 也不是死代码。AI、自动排轴和 Capsule 等入口存在不等于稳定支持或已完成用户验收。

## Current Milestone

**M1 — macOS Core Integrity Baseline**

## Batch State

- **B0 — CLOSED**
  - `BASELINE_CHARACTERIZED`
  - 原生 mouse / keyboard / AX：`NATIVE_INPUT_PENDING`
  - Evidence：[B0 clock & offset truth](evidence/core-integrity/B0-clock-offset.md)
- **D0 — CLOSED**
  - documentation source-of-truth convergence and narrow Obsidian sync
  - Evidence：[D0 documentation SOT](evidence/core-integrity/D0-documentation-sot.md)
- **Next**：C1 — Playback / Presentation Semantic Isolation

`NATIVE_INPUT_PENDING` 不是 PASS，也不表示 B0 发现的产品缺陷已经修复。

## B0 Confirmed Facts

- production clock：`presentation = raw anchor + elapsed + offset`，最后 clamp。
- `+offset` = 歌词提前出现；`-offset` = 歌词延后出现。
- 当前 offset 使用 global key `lyrics.presentationOffset.v1`。
- V3 visible time / progress 会消费 presentation time。
- mouse / drag pointer mapping 属 raw domain。
- keyboard / AX 当前存在 presentation → raw seek 混域。
- 调 offset 本身不会直接 provider seek。
- paused offset subscriber 存在短暂旧值读取路径。
- Fullscreen 复用 V3。
- native input event execution 尚未完成。

详见 [B0 evidence](evidence/core-integrity/B0-clock-offset.md)；本页只保留结论，不复制运行输出。

## Open Core Risks

以下项目仍按当前 Master Plan / batch ownership 作为未关闭核心项；D0 不判断它们已修复：

- C1 clock / transport / seek
- A0 capture source containment
- H1 hash domain
- T1 read/projection fidelity
- T2 lossless edit/timing
- S1 manual adoption persistence
- O1 scoped offset
- R1 reading token consistency
- U1 honest experimental UI
- V1 M1 gate

## Known Test Drift

- `Tests/v3_seek_draft_contract.py`：当前 fake 不满足 production getter；归 C1 owning issue。
- `Tests/fullscreen_lyrics_contract.sh`：静态 literal assertion 与现实现别名写法漂移；不是 clock failure，D0 不修。

## Source-of-Truth Rules

1. 当前用户指令 / 已授权 Batch 决定“现在做什么”。
2. cwd / worktree / HEAD / source 决定“实际改哪份代码”。
3. tag + GitHub Release metadata 决定“发布了什么”。
4. 运行证据 / 精确源码链决定“行为如何”。
5. `docs/STATUS.md` 决定“当前工程推进状态”。
6. Obsidian 保存长期决定、用户体验反馈、项目索引和当前阶段指针；不复制完整工程状态数据库。
7. archive / preview / `.local` / 历史 Agent 报告不能覆盖当前 HEAD。

## Next Executor Contract

**C1 — Playback / Presentation Semantic Isolation**
等待 Planner 下发合同。

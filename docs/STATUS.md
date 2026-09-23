# Spotify Lyrics Current Status

状态页最后更新：2026-09-23。
这是 repository 的唯一滚动工程状态入口；详细运行证据保留在 `docs/evidence/`，不在本页复制完整审计。

文档链：`README.md` → `docs/STATUS.md` → 具体 evidence / batch report / 已授权计划。

## Source Identity

- repo root：`/Users/apple/backup/sptifylyrics`
- branch：`codex/t2-lossless-editing-timing`（T2 从包含 T1 的 final HEAD 建立）
- source HEAD（T2 已验证 production commit）：`40cc1b57fd3a20345d292a5be0f9304f9d5df06d` (`fix: preserve lyric timing on manual edits`)
- H1 production commit：`449df0a6446dd01f250ff84eec34ff87efccf70d`
- T1 production commit：`2963f710c85e0993963d0127514791ee6a19196f`
- release identity：正式 GitHub Release `v0.1.2`，release commit `6528be3103f75fd4f63757855b9d61cd30f757d8`
- status last updated：`2026-09-23`
- tracked/staged 状态：T2 production、focused contract 与 evidence/status 文档分两个提交完成并推送。原始 H1 checkout 中的三份既有 `PROJECT_FULL_AUDIT_*.md` 保持原样，不纳入 T2。

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
- **C1 — CLOSED**
  - `AUTOMATED_VERIFIED`
  - `NATIVE_INPUT_PARTIAL`
  - `USER_EXTERNAL_PENDING`
  - Evidence：[C1 playback / presentation isolation](evidence/core-integrity/C1-playback-presentation-isolation.md)
- **A0 — CLOSED**
  - `AUTOMATED_VERIFIED`
  - 真实 Spotify/Music capture：`USER_VERIFICATION_REQUIRED / NOT_RUN`
  - Evidence：[A0 capture source containment](evidence/core-integrity/A0-capture-source-containment.md)
- **H1 — CLOSED**
  - `AUTOMATED_VERIFIED`
  - 真人 provider 版本切换后小修改保存：`USER_VERIFICATION_REQUIRED / NOT_RUN`
  - Evidence：[H1 hash domain boundary](evidence/core-integrity/H1-hash-domain-boundary.md)
- **T1 — CLOSED**
  - `AUTOMATED_VERIFIED`
  - 真人验收：`USER_VERIFICATION_REQUIRED / NOT_RUN`
  - Evidence：[T1 read / projection fidelity](evidence/core-integrity/T1-read-projection-fidelity.md)
- **T2 — CLOSED**
  - `AUTOMATED_VERIFIED`
  - 真人验收：`USER_VERIFICATION_REQUIRED / NOT_RUN`
  - Planner 定向审查：完成，未发现 Blocker / 必要 Relevant
  - Evidence：[T2 lossless editing / timing](evidence/core-integrity/T2-lossless-editing-timing.md)
- **Next**：S1 尚未开始；本轮停止在 T2 与 S1 之间。

`NATIVE_INPUT_PENDING` 不是 PASS，也不表示 B0 发现的产品缺陷已经修复。

## B0 Confirmed Facts

- production clock：`presentation = raw anchor + elapsed + offset`，最后 clamp。
- `+offset` = 歌词提前出现；`-offset` = 歌词延后出现。
- 当前 offset 使用 global key `lyrics.presentationOffset.v1`。
- C1 后 V3 transport seconds / progress / slider value 使用 playback-domain time；歌词行与逐字 fill 继续使用 presentation time。
- mouse / drag pointer mapping 属 raw domain。
- keyboard / AX slider callback 现在从 playback-domain value 开始并提交 raw seek target。
- 调 offset 本身不会直接 provider seek。
- paused offset subscriber 现在使用 publisher 发出的新 offset 立即重算歌词 projection；transport 不变且不 seek。
- Fullscreen 复用 V3。
- search preview lyric-row 使用 identity guard；preview B 不得 seek live A，同一 live identity 仍允许。
- native mouse / keyboard / AX 外部事件本轮未在真实 AppKit host 中运行，保留 `NATIVE_INPUT_PARTIAL`。

## A0 Confirmed Facts

- Automatic live capture now accepts only explicit ready Spotify Desktop provenance; Apple Music, unknown, mock/preview, unavailable, and no-identity contexts fail closed before Spotify discovery.
- Source, track identity, and generation are carried through startup and final adoption checks; a source/track change during asynchronous startup stops the request and cannot adopt a late result.
- ScreenCaptureKit samples carry active stream/session generation; segment boundaries invalidate and drain queued callbacks before the next segment can receive samples.
- Automatic alignment requires a newly advanced coordinator generation and an exactly generation-matched handoff; it cannot reuse an older `lastPartialReport`.
- Local-file alignment remains independent of live capture and is not disabled by an active Music source.
- The automatic switch remains opt-in and Release-reachable. Real ScreenCaptureKit/Spotify/Music capture was not run; user verification remains `USER_VERIFICATION_REQUIRED / NOT_RUN`.

详见 [A0 evidence](evidence/core-integrity/A0-capture-source-containment.md)；本页不复制完整运行输出。

## H1 Confirmed Facts

- provider/version `contentHash` 继续只承担版本记录与去重身份；既有算法和固定预期未改变。
- translation/reading/timing/editor compare-and-save 使用从 canonical stored `lyric_lines` 计算的 `sourceContentHash`。
- 可编辑版本的 `document` 可能已叠加 timing 或 locked reading；H1 不从该显示投影反算规范源身份。
- 首次打开、provider A → B → A、manual 选择、正确身份保存、保存后继续加载、错误身份拒绝/no-write 与迟到异步结果均已通过临时 SQLite 自动合同。
- repository `sourceContentMismatch` 防线保留；无 schema 迁移、历史 hash 重算或用户数据库访问。
- 真人“切 provider 版本后小修改保存”未运行，保持 `USER_VERIFICATION_REQUIRED / NOT_RUN`。

详见 [H1 evidence](evidence/core-integrity/H1-hash-domain-boundary.md)。

## T1 Confirmed Facts

- partial unsynchronized mask、有效零秒、占位行和行结束时间贯穿 repository → session → editor draft；model/session/draft 保留 `nil` 与空集合区别，SQLite 对无 timed row 的现有映射为 `nil`。
- 旧 locked-reading overlay 仍生效，同时原文、行时间、timed spans、performer、language、translation projection、同版本 timing attachment UUID 与 canonical source hash 保留。
- editor draft 内切换同一歌词版本的译文只改变译文文本；锁定读音、逐字 spans、performer/language、attachment UUID 与规范源身份保持一致。
- 重复加载与切换 session/editor 版本未改变隔离 fixture 的任何数据库表或 `data_version`；无 schema 或用户数据变更。
- 新版本保存是否继续 timing attachment 属 T2，本轮未处理。真人验收保持 `USER_VERIFICATION_REQUIRED / NOT_RUN`。

详见 [T1 evidence](evidence/core-integrity/T1-read-projection-fidelity.md)。

## T2 Confirmed Facts

- Editor copy 与 library revision 均把仍兼容的真实 spans 写入子版本自己的新 timing attachment；attachment 在同一事务中写入，绑定子版本和其 canonical source hash，父版本/父 attachment 保持不变。
- TTML/YRC 真实解析 fixture 经保存、关闭原 helper scope、重新打开 SQLite 后，spans、行时间、语言、performer（有值时）、部分时间轴 mask、renderer input 和 locked-reading layer 按各 fixture 保留。
- 原文或行时间使部分 spans 失配时，编辑器与 library revision 在写入前给出损失数量；取消不写入，确认后只保存兼容余量。只改译文继续通过 translation layer，不新增歌词版本或 timing attachment。
- timing payload 现在须通过文本、UTF-16 范围与时间约束校验，损坏 attachment 不参与自动 word-timing 优先级；用户 preferred/locked 版本优先级保持不变。
- attachment 插入注入失败会回滚子版本、attachment、选择更新及同事务内容。无 schema 迁移或历史 attachment 改写。
- T2 真人体验验收保持 `USER_VERIFICATION_REQUIRED / NOT_RUN`。

详见 [T2 evidence](evidence/core-integrity/T2-lossless-editing-timing.md)。

详见 [B0 evidence](evidence/core-integrity/B0-clock-offset.md)；本页只保留结论，不复制运行输出。

## Open Core Risks

以下项目仍按当前 Master Plan / batch ownership 作为未关闭核心项；T1 本轮只关闭 read/projection fidelity，不判断这些项目已修复：

- S1 manual adoption persistence
- O1 scoped offset
- R1 reading token consistency
- U1 honest experimental UI
- V1 M1 gate

## Known Test Drift

- `Tests/fullscreen_lyrics_contract.sh`：静态 literal assertion 与现实现别名写法漂移；不是 C1 clock failure，本轮未为此扩展修复。

## Source-of-Truth Rules

1. 当前用户指令 / 已授权 Batch 决定“现在做什么”。
2. cwd / worktree / HEAD / source 决定“实际改哪份代码”。
3. tag + GitHub Release metadata 决定“发布了什么”。
4. 运行证据 / 精确源码链决定“行为如何”。
5. `docs/STATUS.md` 决定“当前工程推进状态”。
6. Obsidian 保存长期决定、用户体验反馈、项目索引和当前阶段指针；不复制完整工程状态数据库。
7. archive / preview / `.local` / 历史 Agent 报告不能覆盖当前 HEAD。

## Next Executor Contract

**S1 — Manual Adoption Persistence**
T2 自动验收及 Planner 定向审查已完成，未发现 Blocker / 必要 Relevant；真人验收保持 `USER_VERIFICATION_REQUIRED / NOT_RUN`。S1 尚未开始。

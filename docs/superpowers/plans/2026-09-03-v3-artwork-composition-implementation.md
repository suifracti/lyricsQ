# Spotify Lyrics V3 Ambient / Stage / Classic 三模式构图最小实施计划

> **状态**：PENDING APPROVAL / IMPLEMENTATION PLAN  
> **制定日期**：2026-09-03  
> **权威基线**：`e332bf97d3eb81313430588665392095ccfeea2b`  
> **设计依据**：`docs/superpowers/specs/2026-09-03-v3-artwork-composition-design.md` (Commit: `e332bf9`)  
> **实施边界**：本文件为纯文档计划（Docs-only Implementation Plan）。本轮不修改任何 Swift 代码，不开始任何代码实施，不 push，不开 PR。

---

## 1. Baseline（基础环境与约束）

- **Worktree 路径**：`/private/tmp/spotifylyrics-ui-visual-baseline`
- **当前分支**：`antigravity/ui-visual-baseline`
- **Base HEAD**：`e332bf97d3eb81313430588665392095ccfeea2b`
- **设计依据提交**：`e332bf9` (`docs: clarify Reduce Motion scope in V3 composition design contract`)
- **代码实施基线**：Commit `225edf3` (`V3BounceButtonStyle` Pressed-State Correction PASS)
- **保护约定**：主仓库脏工作区 `/Users/apple/backup/sptifylyrics` 绝对只读且不受任何操作影响。

---

## 2. Already Aligned / NO CHANGE（已对齐/绝不实施项）

以下系统与模块在 Design Contract 中已被确认为现状已满足或严格冻结项，**绝对不为其创建任何代码修改任务**：

### 2.1 全局共享层（Shared）
- **连续几何插值**：`adaptiveSplitMetrics` 基础插值算法与连续自适应方向；
- **响应式体系**：`compact`、`regular`、`wide` 的既有阈值判定结构；
- **歌词层级与宽度**：歌词排版阶梯（Primary / Secondary / Metadata）、最大可读行宽限制（Measure）；
- **背景管线**：`AppleMusicImmersiveV3BackdropView` 宿主结构、`normalizedBlur`、palette 提取与高斯模糊管线；
- **运行时与核心状态机**：`Presentation Clock`（5Hz 定时器与回弹保护）、`line index` 计算与分发、切行过渡模式（`.softBoundary` / `.immediate`）；
- **动效合同**：歌词视口滚动 / 焦点行 / 距离权重与已验收 `V3BounceButtonStyle` 的 Reduce Motion 合同；
- **外围系统**：Toolbar IA（工具栏布局与悬停区）、Settings 基础架构、Fullscreen 全屏模式几何、Floating 悬浮窗几何。

### 2.2 Ambient（环境陪伴）
- 完整前景 1:1 方形封面的物理存在；
- 左右分栏的歌词持续阅读列；
- 曲目元数据（Metadata）与播放控制（Transport Controls）在空间和层级上依附于前景封面的基础排布；
- 显式 `lyricsFocus` 紧凑模式；
- 现有的封面低频外溢环境底图机制。

### 2.3 Stage（整窗舞台）
- 单张高清封面作为全屏舞台唯一主体；
- 严格遵循 `aspect-fit` 且完整未裁切的比例保护；
- 绝对不叠加第二张前景小封面；
- 歌词与 HUD 统合为浮层（Overlay）而非侧边分栏的基本形态。

### 2.4 Classic（经典大专辑）
- 放大专辑 / Album-first 的核心身份与权重视重；
- 前景封面具有更大尺寸上限（最大可达 560pt）；
- 经典左右分栏（Split Layout）及现行分栏比例计算基准；
- 局部放大裁切（Cropped Substrate）的动态底图方向；
- 歌词独立的平行阅读列。

---

## 3. Minimal Implementation Candidates（最小实施候选清单）

严格基于已批准的 Relevant design gap 与代码现状，拆解为以下独立候选任务：

---

### Candidate 1 (Merged B + C) — Stage 底部浮层纵向收敛与矮窗（Short）弹性压缩

- **对应 Gap**：Stage 底部 overlay（双 veil + 歌词流 + HUD）占用过大，遮挡主封面下半部 50%~80%，重心下沉；矮窗下固定大比例严重恶化。
- **合并理由**：代码盘点确认，标准/宽屏下的浮层高度（`lyricHeight = max(..., min(..., canvasHeight * 0.52))`）、矮窗下的下限截断（`max(220, ...)` / `max(260, ...)`）、双 veil 渐变覆盖（`canvasHeight * 0.82`）以及底部垂直堆叠均集中在同一个方法 `stageTheaterLayout(in:)` 中。同一段几何计算微调即可同时解决标准窗与矮窗问题，无需引入新架构，共用同一组验收用例，因此安全合并为一个最小任务。
- **代码定位**：
  - `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift`:
    - `stageTheaterLayout(in:)` (lines 351–418)：
      - `lyricHeight` 计算（lines 359, 364, 369）；
      - 底层大渐变 veil（lines 387–399，高度 `max(220, canvasHeight * 0.82)`）；
      - 垂直信息群布局 `VStack(spacing:) { lyricsCol; hudView }`（lines 404–416）；
  - `SpotifyLyrics/Views/Components/AppleMusicImmersiveV3BackdropView.swift`:
    - `stageArtworkLayers` 中的 `stageReadingVeil`（lines 292–305）。
- **实施范围与规则**：
  - **Primary implementation surface（核心实施面）**：
    - 优先且仅聚焦于：`lyricHeight` 计算、overlay 垂直几何尺寸、以及 HUD / 歌词在底部的垂直占用；
    - 实施目标：通过最小的 geometry 调整，在 Standard / Wide 下明显降低底部浮层高度并收敛，使主 artwork 恢复为整窗第一视觉主体，消除“上半张封面、下半张 UI”的二分割裂感；
    - Short Window 目标：在视口高度接近最小高度（~500pt）时，歌词浮层弹性收敛，不机械占用固定大高度，保住完整 aspect-fit 舞台主体与当前播放行及 HUD 控制按钮；
    - 保持底线：当前行歌词对比度与可读性不降低，播放控制按钮完整可见可点，不修改 Stage artwork aspect-fit 算法，不引入新全局断点。
  - **Veil 规则（Conditional Sub-scope，非默认修改项）**：
    - `stageReadingVeil` / 外层 veil 先保持 **NO CHANGE**；
    - 严禁因为代码位置顺手就去改动 veil；
    - 严禁重写 backdrop、严禁改动 normalizedBlur、严禁重做 gradient 系统；
    - **唯一允许调整条件**：仅在真实 Stage Standard / Wide / Short 截图明确证明“即使 overlay geometry 已充分收敛，veil 本身依然明显造成下半张 artwork 被淹没吞噬”时，才允许在同一个 Candidate 1 中做最小的 veil presentation 调整；
    - 因此 Candidate 1 仍为一个统一任务，但 veil 属于有严格触发前提的条件子范围（conditional sub-scope），绝非既定必改项。

---

### Candidate 2 (Candidate F) — Classic 紧凑视口（Compact）当前歌词首屏可见性保障

- **对应 Gap**：Compact 视口下使用垂直 `ScrollView`，由于 `trackHeight` 占比过大（`max(420, height * 0.76)`），导致封面占满首屏，当前播放歌词被完全推至首屏下方，必须手动滚屏才能看见。
- **代码定位**：
  - `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift`:
    - `classicCompactLayout(in:)` (lines 255–286)：
      - `trackHeight = max(420, geometry.size.height * 0.76)`（line 258）；
      - `coverSize` 约束计算（lines 259–265）；
      - `ScrollView(.vertical)` 内部的 `trackColumn` 与 `lyricsColumn` 纵向堆叠排布（lines 267–283）。
- **实施目标**：
  - 在 Compact 窄视口下，重构封面与歌词的垂直空间配比（如按比例紧凑化封面与元数据内边距），确保在不滚动的前提下，**当前播放歌词首行在首屏保持立即可见或处于同一首屏阅读视距内**；
  - 维持 Classic 模式的 Album-first 实体唱片身份，不破坏封面展示质感；
  - 严格不影响 Desktop Standard / Wide 正常的左右分栏双栏排布；
  - 绝对不触碰歌词切行动效与滚动时钟。

---

### Candidate 3 (Candidate D) — Stage 用户设置描述文案校准

- **对应 Gap**：设置界面中 Stage 模式的说明文案为历史遗留描述（“以单张专辑封面构成全景舞台，左下融入控制，右侧悬浮歌词”），与当前实际渲染（底部中央 HUD + 居中歌词）不符。
- **代码定位**：
  - `SpotifyLyrics/Settings/AppSettingsStore.swift`:
    - `V3ArtworkPresentation.detail` (line 50)：
      ```swift
      case .stage: return "以单张专辑封面构成全景舞台，左下融入控制，右侧悬浮歌词"
      ```
- **实施目标**：
  - 仅校准 `case .stage` 返回的用户可见描述字符串，准确表述为单张完整艺术封面构筑全屏舞台、底部融入信息与歌词浮层；
  - 严禁重构 Settings 结构，不变更偏好设置存储 key，不修改运行时行为，其他模式文案原样保留。

---

### Candidate 4 (Candidate E) — Classic 分割线（Divider）视觉弱化

- **对应 Gap**：分栏中间的垂直分割线存在感较强，强化了左右两个独立 Dashboard 面板的拼接感。
- **代码定位**：
  - `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift`:
    - `classicSplitLayout(in:regime:)` (lines 326–328, 335–337)：
      ```swift
      Divider()
          .overlay(LyricsDesignTokens.controlBorder.opacity(0.72))
      ```
- **实施意图与边界（只冻结视觉目标，不冻结实现手段）**：
  - **视觉目标**：
    - 保持 Classic 模式的 split identity；
    - 严格保持既有左右分栏比例（Split Ratio）与布局结构；
    - 消除左右两侧像两块独立 Dashboard 面板的生硬割裂感，使两栏感知为同一块有机艺术画布；
    - 分割线 / 分隔线索（Divider / separation cue）不再成为视觉中心，必须极大程度退居幕后或自然融入留白。
  - **实现手段开放性**：
    - 本 plan **绝对不提前冻结具体实现手段**（不提前决定必须是删除、采用微渐变、还是调整特定透明度数值）；
    - 允许实施 Agent 在实际执行时，基于当前真实界面截图，从现有 separation presentation 空间中选择**最小改动方案**；
    - 若代码评估显示消除面板割裂感需要大规模 layout 重排或重构，则立即标记为 `DEFER`。

---

### Candidate 5 (Candidate A) — Ambient 前景封面与环境场视觉交融微调

- **对应 Gap**：前景 `ArtworkView` 带有清晰白色描边与投影，在某些背景下容易产生像贴片贴在壁纸上的视觉割裂感。
- **代码定位**：
  - `SpotifyLyrics/Views/Components/ArtworkView.swift`:
    - 描边修饰符（lines 38–41：`.stroke(LyricsDesignTokens.controlBorder, lineWidth: 1)`）；
    - 阴影修饰符（line 42：`.shadow(...)`）；
  - `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift`:
    - `trackColumn` 中的 `ArtworkView` 容器外层修饰（line 438, lines 510–516）。
- **实施意图与边界（最小前景 presentation 微调）**：
  - **实施意图**：
    - 仅允许对前景封面进行**最小的 presentation 调整**；
    - 目标：保持完整实体 1:1 方形封面，同时弱化“独立卡片生硬贴在背景上”的贴片感与割裂感；
    - 歌词阅读列始终保持为长时沉浸阅读主焦点；
    - 严格守住边界：不改动 Ambient split geometry，不改动 backdrop / palette / normalizedBlur 核心算法，不添加彩色发光（halo/glow），不新增大型底板卡片容器。
  - **实施流程与选择范围**：
    - 实施 Agent 必须先在真实 Standard / Wide / Compact 截图中审视贴片感的实际来源，再从当前 foreground artwork presentation 中选择**最小的一处**进行调整（可能涉及既有边框处理、既有阴影处理、或前景容器外围 presentation，但 plan 不预先规定具体选哪一个）；
  - **严格 Defer 规则**：
    - 如果该问题的解决必须依赖同时修改多层材质、添加复杂渐变 mask、侵入 backdrop、或引入全新融合系统，则**立即判定为 `DEFER — requires separate visual exploration`**，严禁硬做或侵入底层算法。

---

## 4. Candidate Prioritization（候选任务优先级与分类）

| 候选标识 | 候选任务名称 | 优先级 | 决策 rationale（依据） |
|---|---|:---:|---|
| **Candidate 1** | **Stage 底部浮层纵向收敛与矮窗弹性压缩**<br>*(Merged B + C)* | **P0** | **最高构图收益**。Stage 当前遮挡 50%~80% 封面，严重背离“单张封面为主舞台”的合同底线。代码高度内聚，合并后优先收敛 overlay 垂直几何；veil 作为条件子范围（截图证明有必要时才微调），一次性解决 Stage 核心视觉危机。 |
| **Candidate 2** | **Classic Compact 歌词首屏可见性保障**<br>*(Candidate F)* | **P1** | **关键功能可用性**。Classic 在窄视口下将当前歌词完全挤出首屏，违背了“歌词为核心内容”的全局合同，必须优先解决。 |
| **Candidate 3** | **Stage 用户设置描述文案校准**<br>*(Candidate D)* | **P1** | **无风险单点校准**。消除用户设置描述与实际底部居中渲染的明显脱节，单一字符串修改，0 代码回归风险。 |
| **Candidate 4** | **Classic 分割线视觉弱化**<br>*(Candidate E)* | **P2** | **低风险视觉目标收敛**。保持 split 结构，不提前冻结具体实现手段，由实施 Agent 基于真实截图从现有 separation presentation 中选最小手段，使 Divider 不成为视觉中心。 |
| **Candidate 5** | **Ambient 前景封面视觉交融微调**<br>*(Candidate A)* | **P2** | **谨慎探索项**。基于真实截图从前景 presentation 中选择最小一处调整，弱化贴片感；若需多层/复杂方案则立即 `DEFER`。 |

---

## 5. Execution Isolation（执行隔离与提交流程）

每个 implementation candidate 必须保持严格的代码隔离与提交独立性：

1. **绝对禁止大杂烩提交**：严禁在一个 commit 中同时混杂两个及以上模式的代码修改；
2. **提交拆分合同**：
   - **Commit 1 (P0)**：Candidate 1 (Stage Overlay + Short Contraction 几何收敛，veil 仅限满足条件时微调)；
   - **Commit 2 (P1)**：Candidate 2 (Classic Compact 首屏歌词排布收敛)；
   - **Commit 3 (P1)**：Candidate 3 (Stage Settings 文案校准)；
   - **Commit 4 (P2)**：Candidate 4 (Classic Divider 视觉弱化，按最小手段实现)；
   - **Commit 5 (P2)**：Candidate 5 (Ambient 前景 presentation 最小微调，若未 DEFER)；
3. **每步独立闭环**：每个 Candidate 实施后，必须单独执行该候选的实机截图验证与代码审查，确认无回归后再进入下一个 Candidate。

---

## 6. Visual Verification Matrix（可视化验收矩阵）

为真正进入实施的候选定义定向最小实机观察矩阵，不运行无关的大全量测试：

### 6.1 Ambient 验收（针对 Candidate 5）
- **Standard (常规宽窗)**：封面保持完整方正实体感，边框与环境场自然衔接，无悬空白色贴纸感，歌词清晰处于主阅读列；
- **Wide (宽屏视口)**：封面尺寸受上限约束，两侧留白协调，歌词 Measure 稳定；
- **Compact (紧凑视口)**：分栏自适应平滑，歌词未被过度挤压。

### 6.2 Stage 验收（针对 Candidate 1 & 3）
- **Standard (常规宽窗)**：主 artwork 完整展露，底部 overlay 显著下移收敛，不形成“封面/UI 各占一半”的二分感；当前歌词行高对比度可读，HUD 居中紧凑；
- **Wide (超宽视口)**：Aspect-Fit 封面全画幅居中，底部信息群宽度受限居中，剧场舞台感强烈；
- **Short Window (高度受限)**：视口拉矮至极限高度时，歌词区域弹性压缩行数上下文，当前播放行与 HUD 依然清晰可见，主封面完整主体未被淹没；
- **Settings**：设置弹窗内 Stage 选项描述文字与当前真实底部中央渲染完全吻合。

### 6.3 Classic 验收（针对 Candidate 2 & 4）
- **Standard (常规宽窗)**：左右分栏结构清晰，封面与元数据形成 Album Block；Divider 极大程度退居幕后，两栏呈现于同一连续画布上；
- **Wide (超宽视口)**：大封面具展现力，左右不孤立；
- **Compact (紧凑视口)**：首屏即能同时看到当前曲目与**当前播放的焦点歌词行**，无需滚屏即可感知正在唱响的歌词。

---

## 7. Reduce Motion Rule（动画约束原则）

- **严格遵守 Design Contract**：本实施计划**不新增任何全局 composition-level 的 Reduce Motion 规则**；
- **按候选就地评估（Per-Candidate Rule）**：
  - Candidate 1、2、4、5 均仅对静态几何比例（frame / padding / height / opacity）进行微调，**不涉及新增任何构图级动画过渡**，因此完全继承既有已验收的 Reduce Motion 行为（歌词滚动无位移、模糊归零、seek immediate、按钮无物理形变）；
  - 若未来某个 Candidate 在实施中确需引入新的动效过渡，必须在该 Candidate 实施时单独定义并实机实测其 Reduce Motion 表现。

---

## 8. Deferred / OUT OF SCOPE（明确延期与范围外清单）

以下事项坚决不纳入本次实施范围：

1. `normalizedBlur` 数值与背景提取算法（palette、模糊着色器）；
2. 封面图像质量、源解析与 Provider 接入；
3. 音频播放、`Presentation Clock`、5Hz 定时器、`line index` 计算；
4. 歌词切行动效合同（`0.30s / 0.34s` soft transition 与 immediate seek）；
5. 歌词字体、字阶与字重重构；
6. Toolbar IA、设置中心架构重构、全屏与悬浮窗架构；
7. 三种模式归一化或重构为统一排版引擎；
8. 搜索、对齐详情、本地歌词导入等业务逻辑；
9. 任何 Stage B 功能；
10. 全局设计 Token 系统大重构。

---

## 9. Stop Conditions（停止条件）

- 本文档为纯规划文件，任务目标为确立最小实施计划；
- **严禁修改任何 Swift 源代码**；
- **严禁开始实施任何 Candidate**；
- **严禁执行 push 或新建 PR**；
- **严禁触碰或清理其他工作区与主仓库**；
- 计划文档创建并提交后，任务立即停止。

---

## 10. 结论

`V3_COMPOSITION_PLAN_STATUS=PASS`

本实施计划将 V3 构图设计规范精准收敛为 5 个最小、独立、低风险的实施候选（其中 Stage Overlay 与 Short 合并），优先级清晰，隔离边界明确，具备高度工程可执行性。

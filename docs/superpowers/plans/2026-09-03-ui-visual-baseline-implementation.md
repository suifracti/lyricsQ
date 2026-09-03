# Spotify Lyrics UI Visual Baseline Implementation Plan

- **Date**: 2026-09-03
- **Status**: Draft / Ready for Review
- **Document Path**: `docs/superpowers/plans/2026-09-03-ui-visual-baseline-implementation.md`
- **Scope**: Strictly docs-only implementation plan for the UI Visual Baseline minimal correction.

---

## 1. Baseline

- **Worktree**: `/private/tmp/spotifylyrics-ui-visual-baseline`
- **Branch**: `antigravity/ui-visual-baseline`
- **Current HEAD**: `527c14b33d24ebff4013442df4aa928a6aaed415`
- **Design Source Commit**: `527c14b33d24ebff4013442df4aa928a6aaed415`
- **Authoritative Design Spec**: `docs/superpowers/specs/2026-09-03-ui-visual-baseline-design.md`
- **Code Baseline**: Branch directly branched from `origin/main` at `6e5064a2a8575d02dc515e41b44a9061df91a349`
- **Execution Mode**: Strictly docs-only. No Swift source code is modified in this plan. Implementation will only begin after approval.

---

## 2. Already Aligned / NO CHANGE (不实施清单)

经只读盘点与设计基线比对，以下核心要素已完全被当前代码实现满足，属于现有事实（`Existing implementation / preserve`），**明确不实施任何修改，不为其创建任何 implementation task**：

| 特性分类 | 具体项 | 现行代码事实 / 理由 | 处置策略 |
| :--- | :--- | :--- | :--- |
| **Typography** | Lyric emphasis hierarchy | `LyricsDesignTokens.lyricEmphasis` 已精准实现 Active (1.0/blur 0/bold)、Adjacent (0.58/blur 0.4/semibold)、Distant (0.36/blur 1.6/medium) 三级景深 | **不实施 / NO CHANGE** |
| **Typography** | Responsive lyric sizing | `lyricEmphasis` 中依据可用宽度（520~1360）与可见图层惩罚连续插值主字号 26~34pt 的算式成熟稳定 | **不实施 / NO CHANGE** |
| **Typography** | 680pt readable measure | `LyricsDesignTokens.readableLyricLineMaxWidth = 680` 已在 V3 视口与换行约束中生效 | **不实施 / NO CHANGE** |
| **Window Dimensions** | Main window size constants | `technicalMinimumMainWindowSize` (760×520)、`comfortableMainWindowSize` (800×600)、`defaultMainWindowSize` (1040×680) 已在代码中全局定义 | **不实施 / NO CHANGE** |
| **Spacing** | Spacing/token vocabulary | 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 语义阶梯已在现有代码与规范中明确，不新增也不重写 token | **不实施 / NO CHANGE** |
| **Spacing** | 特殊 spacing 值 | 26 (分栏)、28 (标题栏对齐)、34 (安全边距)、64 (超宽边距)、72 (画布留白)、7 (辅歌词空隙) 经光学校准保留 | **不实施 / NO CHANGE** |
| **Material & Backdrop** | Current background direction | 封面驱动、深沉克制的背景美学已确立并冻结，杜绝杂乱高亮 | **不实施 / NO CHANGE** |
| **Material & Backdrop** | Background algorithm | `AppleMusicImmersiveV3BackdropView` 的 `normalizedBlur`、多重高斯漫反射与 `backdropGradient` 管线严格冻结 | **不实施 / NO CHANGE** |
| **Motion** | Reduce Motion | 无位移、无 scale morph、无 blur morph、仅保留约 0.12s opacity 短淡化已在实机通过验收 | **不实施 / NO CHANGE** |
| **Motion** | Soft lyric transition | 0.44s 视口平滑、0.30s 聚焦、0.34s 弱化及 `.softBoundary` / `.immediate` 派发语义已在 Stage A 冻结 | **不实施 / NO CHANGE** |
| **Multi-surface** | Fullscreen transition semantics | 全屏歌词使用共享 `LyricsTransitionPolicy` 且视口独立定位，已完全对齐 | **不实施 / NO CHANGE** |
| **Multi-surface** | Floating transition semantics | 悬浮歌词以当前行为绝对重心，轻量化逻辑已对齐 | **不实施 / NO CHANGE** |
| **Multi-surface** | Main / Fullscreen / Floating 几何结构 | 各表面独立布局与特化展现保持现状，不进行抽象合并 | **不实施 / NO CHANGE** |
| **Core Architecture** | Playback / Provider / Index / Clock | `LyricsPresentationClock`、会话、1.25s 轮询防回退、行索引计算属于底层基石，绝对禁止触碰 | **不实施 / NO CHANGE** |

---

## 3. Task 1 — V3BounceButtonStyle pressed-state correction (唯一代码任务)

这是本次 Visual Baseline 实施计划中**唯一被允许进入实施的代码任务**。

### 3.1 Problem
在 `SpotifyLyrics/Views/MainWindow/AppleMusicImmersiveV3WindowView.swift` 中，现行 `V3BounceButtonStyle` 定义如下：
```swift
struct V3BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.84 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
```
**缺陷分析**：
1. **缩放幅度过大**：按压时缩小至 `0.84`（压缩达 16%），视觉形变极其突兀；
2. **回弹感过强**：使用 `.spring(response: 0.22, dampingFraction: 0.65)` 弹簧动画，按键松开（release）后产生明显的 bounce 振荡；
3. **冲突**：与已批准的 Visual Baseline 第 4 节「Control-State Semantics」严重冲突——控件按下状态必须提供即时明确反馈，禁止夸张缩放变形，不得出现弹簧跳跃感。

### 3.2 Scope
**严格限制范围**：
- 只允许修改：
  1. `V3BounceButtonStyle` 结构体本身（位于 `AppleMusicImmersiveV3WindowView.swift`）；
  2. 若确有必要，与该 style 直接关联的最小验证测试代码。
- **严禁越界行为**：
  - 不得重构 Toolbar 或任何控制条；
  - 不得修改播放状态逻辑（`state.togglePlayPause()` 等）；
  - 不得修改按钮 action、触发器或手势；
  - 不得修改按钮图标、尺寸、frame 或 padding；
  - 不得修改按钮所处的布局结构；
  - 不得修改颜色体系或材质；
  - 不得创建全局通用 ButtonStyle 抽象层；
  - 不得顺手统一修改其他视图中的按钮；
  - 不得触碰其他窗口或表面控件。

### 3.3 Implementation Intent
- **改进目标**：
  - 保留按下时清晰可感知的 pressed 反馈；
  - 彻底去除 `0.84` 级别的夸张缩放；
  - 彻底去除 spring / bounce 弹跳感；
  - 松开按键后平稳、直接返回 idle 状态；
  - 在 Reduce Motion 开启时，完全消除 scale 与 spring 形变动效。
- **开放度设计**：
  - 本 Plan **不在文档中预先冻结具体的 replacement scale 数值**（不提前预设必须是 0.96、0.98，亦不硬性限制为纯 opacity 衰减或明度调节）；
  - 实施 Agent 应基于“最小代码改动原则”，在满足克制与即时反馈的前提下，选取最干净直接的实现方式。

### 3.4 Acceptance Criteria (10项验收准则)
1. **Idle 外观一致**：未按压时的按钮外观、尺寸、材质与现状绝对一致；
2. **Hover 外观一致**：鼠标悬停时的按钮外观与交互反馈与现状一致；
3. **Pressed 清晰可感知**：按压状态下依然提供明确、即时的视觉反馈；
4. **无大幅缩小**：彻底杜绝 `0.84` 级别的夸张缩放变形；
5. **无 Spring/Bounce**：按键释放后平稳复原，无弹簧振荡与弹跳感；
6. **不影响 Playback Action**：播放、暂停、切歌等原有动作响应准确无损；
7. **不改变布局尺寸**：按钮及其外围容器的测量与布局尺寸完全不变；
8. **Reduce Motion 适配**：系统开启 Reduce Motion 时，无 scale 或 spring 动效残留；
9. **影响范围精确隔离**：仅使用 `V3BounceButtonStyle` 的 V3 按钮受到预期影响（主播放暂停按钮、Stage 播放暂停按钮、`V3TransportIconButton`）；
10. **无其他视觉范围修改**：代码 diff 严格局限在目标 style 附近，无附带修改。

---

## 4. Readability Verification Matrix (只读视觉验证任务)

本部分**纯粹作为后续验收时的视觉验证任务，严禁将其作为代码修改任务**。

### 4.1 验证矩阵规划 (未来截图与实机观察)

| 验证维度 | 核对工况与组合 | 验收关注点 |
| :--- | :--- | :--- |
| **窗口形态 (Window)** | 1. `760 × 520` (Technical Minimum)<br>2. `800 × 600` (Comfortable Reference)<br>3. `1040 × 680` (Default Standard)<br>4. Wide (宽屏，如 1440 宽)<br>5. Short (扁平矮窗，如 900×530) | • 矮窗下封面不挤压控制栏<br>• 760 极限下无文本截断或组件溢出<br>• 宽屏下歌词行宽受控于 680pt |
| **歌词组合 (Lyrics)** | 1. 纯原文<br>2. 原文 + 翻译<br>3. 原文 + Romaji (罗马音)<br>4. 原文 + Kana / Ruby (假名/注音)<br>5. 多辅助层同时开启 (四层并存)<br>6. 超长歌词自然换行 | • 汉字与上方 Ruby 无交叉重叠<br>• 辅歌词与主歌词层级清晰<br>• 多层并存时自适应压缩，无纵向撞车<br>• 换行时不拆散词素与注音 |
| **极端封面 (Covers)** | 1. 亮白 / 浅色封面 (Bright)<br>2. 纯黑 / 极暗封面 (Very Dark)<br>3. 高饱和 / 刺眼杂色封面 (High Saturation)<br>4. 单色 / 黑白封面 (Monochrome) | • 亮色封面白色文字对比清晰无眩光<br>• 极暗封面有背景景深层次不泛白<br>• 高饱和封面无杂色冲撞歌词区<br>• 黑白封面灰阶过渡自然无断层 |

### 4.2 规则与约束
- **铁律**：**只有在截图或实机验证中发现了真实的视觉缺陷或崩溃，才允许另外单独发起新的定向 implementation task**。
- **禁止预调**：当前 plan 绝对**不允许预先调整**以下任何参数：
  - `font size` (字号)
  - `opacity` (不透明度)
  - `blur` (动态模糊)
  - `spacing` (间距)
  - `backdrop` (背景呈现)
  - `background algorithm` (背景渲染算法)

---

## 5. Deferred / OUT OF SCOPE (推迟与范围外清单)

明确以下所有项均**处于本次实施范围之外 (OUT OF SCOPE)**，严禁在本轮或随后的 Task 1 中顺带修改：

1. **V3 三种封面构图精修**：Ambient、Stage、Classic 构图算法保持现状；
2. **Toolbar IA / Redesign**：不重构 Toolbar 信息架构与按钮布局；
3. **Settings Redesign**：不重构设置中心与偏好选项界面；
4. **Background Algorithm**：不修改 `normalizedBlur`、高斯模糊级数与色彩管线；
5. **Window Architecture Unification**：不尝试统一 Main、Fullscreen、Floating 的底层窗口控制器或几何架构；
6. **Empty / Loading / Error States**：不修改歌词加载中、空状态、候选选择等状态视图；
7. **Search / Import**：不触碰歌词搜索、导入与词源匹配逻辑；
8. **Stage B**：不开启任何 Stage B 范围事务；
9. **Provider & Playback**：不修改任何音频提供者、播放控制或播放器状态机；
10. **Presentation Clock & Line Index**：不修改时钟锚点、调度或行索引判定；
11. **Soft Transition**：不修改平滑过渡算法或转场模式语义；
12. **全局 ButtonStyle Abstraction**：不创建全 App 通用的新 ButtonStyle 体系；
13. **Spacing 大规模 Token 化**：不把零散常数强制整编为新 Token；
14. **Typography 全局重构**：不对 App 字体进行无差别统一重构。

---

## 6. Execution Order (严格执行顺序)

实施阶段只允许按以下单一顺序流水线执行：

```
┌────────────────────────────────────────────────────────┐
│ Step 1: 实现 V3BounceButtonStyle 最小修正 (唯一代码修改) │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 2: 定向验证受影响按钮 (标准播放、Stage播放、IconButton) │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 3: macOS Reduce Motion 定向实机验证 (无弹跳/形变)   │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 4: 执行 Debug Build (验证编译 0 error / 0 warning) │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 5: 全部 PASS 即停止！不创建 Task 2，不改其他 UI     │
└────────────────────────────────────────────────────────┘
```

**重要说明**：Readability Verification Matrix 纯属后续独立只读验收，绝不与 Task 1 的代码修正混在同一个 implementation commit 中。

---

## 7. Verification Plan (验证方法)

后续实施只需要精简、必要的定向验证：

1. **代码与合同检查**：
   - 检查 `V3BounceButtonStyle` 的 diff，确认未引入新动画队列，未保留 `0.84` 与 `.spring`；
   - 确认无超出范围的无关修改。
2. **工程编译验证**：
   - 运行 Debug build：
     ```bash
     xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug clean build
     ```
   - 确认 `** BUILD SUCCEEDED **`。
3. **V3 按钮实机交互观察**：
   - 运行构建的 App，在普通播放、Stage 模式下分别点击主播放/暂停、上一曲/下一曲按钮；
   - 观察按压时视觉反馈清晰、无大幅收缩、释放无 bounce 弹跳。
4. **Reduce Motion 实机观察**：
   - 在系统开启 Reduce Motion 状态下点击受影响按钮，确认无 spring 动画与缩放变形。
5. **明确不跑无关矩阵**：
   - **不要重新跑**完整歌词时钟大矩阵、provider 回归、网络搜索审计或 Stage A 历史脚本，除非修改意外波及这些代码。

---

## 8. Stop Conditions (停机条件)

- [x] **当前阶段**：本 implementation plan 文档编写完成、自检无误后**立即停止**；
- [x] **严格文档**：不修改任何 Swift 文件；
- [x] **不提前实施**：不开始执行 Task 1 的代码修改；
- [x] **不越权发布**：不执行 `git push`，不创建 GitHub PR；
- [x] **保持隔离**：不清理其他 worktree，不触碰主仓库；
- [x] **单一任务原则**：坚决不新增第二个代码 candidate。

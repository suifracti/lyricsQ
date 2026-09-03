# Spotify Lyrics UI Visual Baseline Design Specification

- **Date**: 2026-09-03
- **Status**: Draft / Ready for Review
- **Document Path**: `docs/superpowers/specs/2026-09-03-ui-visual-baseline-design.md`
- **Scope**: Docs-only visual baseline specification. Does not mutate App Swift code, project configuration, tests, presentation clock, or background algorithms.

---

## 1. Typography Hierarchy (字体层级体系)

Spotify Lyrics 的字体层级以「歌词内容优先、元数据清晰克制、控件辅助静音」为核心原则。排版系统统一采用 Apple 平台的 `.rounded` 设计语言，兼具亲和力与现代感，并通过字重、字号、不透明度与动态模糊的组合，建立强烈的视线景深。

本规范严格**映射并保护现有实现的视觉终值**，不进行机械式的单字号硬编码统一，保留针对屏幕宽度、行可见图层数（Layer Count）与光学视差的微调。

### 1.1 核心层级概览

| 层级名称 | 角色定位 | 基础字号 (pt) | 字重 (Weight) | 前景色 / 不透明度 | 动态处理 (Motion / Blur) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary Lyric (Active)** | 当前焦点歌词原文 | 响应式 `26 ~ 34` (默认基准 27~30) | `.bold` | `primaryText` (RGB 0.96, 0.94, 0.90) / `1.0` | `blur: 0`，视线绝对焦点 |
| **Primary Lyric (Adjacent)** | 上下相邻行歌词 (距离 `distance = 1`) | 相比 Active 略小 `2.0pt` (`24 ~ 32`) | `.semibold` | `primaryText` / `0.58` | `blur: 0.4pt`，近场伴读线索 |
| **Primary Lyric (Distant)** | 远端非活跃歌词 (距离 `distance >= 2`) | 相比 Active 略小 `4.0pt` (`22 ~ 30`) | `.medium` | `primaryText` / `0.36` | `blur: 1.6pt`，大景深弱化背景 |
| **Secondary Lyric (Translation)** | 歌词人工/AI 翻译 | 响应式 `14 ~ 20` (基准 15~18) | `.regular` | `mutedText` (RGB 0.58, 0.60, 0.64) / `effectiveOpacity * 0.72` | 随主行缩放与模糊，下沉 7pt (紧随罗马音时 3pt) |
| **Secondary Lyric (Romaji)** | 日文罗马音辅助发音 | 响应式 `14 ~ 20` (基准 15~18) | `.regular` | `mutedText` / `effectiveOpacity * 0.64` | 比翻译更低饱和度，下沉 7pt |
| **Secondary Lyric (Ruby / Kana)** | 假名注音 (Ruby) 与独立假名行 | Ruby: 主字号 55% (`11 ~ 18`)；独立: `14 ~ 20` | Ruby: 主行同步；独立: `fontWeight` | `secondaryText` (RGB 0.77, 0.78, 0.80) / `rubyOpacity` (`0.82 ~ 0.95`) | 汉字上方贴合注音，或作为独立辅助行 |
| **Song Metadata (Title)** | 歌曲标题 (曲名) | 响应式 `18 ~ 30` (封面比例或紧凑模式) | `.bold` | 纯白 `#FFFFFF` / `1.0` | 柔和阴影 (`black.opacity(0.22)`, radius: 7, y: 2) |
| **Song Metadata (Artist / Album)** | 艺人名与专辑名 | `max(12, titleSize * 0.58)` (`12 ~ 17`) | V3: `.semibold`；标准: `.medium` | 艺人: `primaryText`；专辑: `secondaryText`；分隔符 `·`: white `0.35` | 单行优先，不足时纵向堆叠 |
| **Controls / Labels** | 窗口控制、Toolbar 按钮 | `12 ~ 13` (`auxiliary` / `metadata`) | `.medium` | `secondaryText` (Idle 0.64 ~ Hover 0.92) | 无投影，跟随毛玻璃容器 |
| **Transport Timecodes** | 播放进度时间码 (已播/总长) | `11 ~ 12` (等宽数字特性 `.monospacedDigit`) | `.regular` ~ `.medium` | `mutedText` (0.58 ~ 0.82) | 紧凑排布于进度条两侧 |
| **Utility Badges / Tags** | 悬浮窗状态、音源标签、Ruby 标尺 | `10` | `.medium` / `.semibold` | `secondaryText` / `mutedText` | 胶囊背景内嵌微型文本 |

### 1.2 字体层级细则与保护约束

1. **主歌词响应式算式保全**：
   - 现有实现在 `LyricsDesignTokens.lyricEmphasis` 中依据视口宽度与可见图层计算：
     ```swift
     widthProgress = (min(max(availableWidth, 520), 1360) - 520) / 840
     layerPenalty = max(0, visibleLayerCount - 2) * 1.5
     activePrimary = min(34, max(26, 27 + widthProgress * 8 - layerPenalty))
     ```
   - **设计基线严格保留此动态计算逻辑**：宽窗下主字自然延展至 34pt，窄窗或多图层（原文+假名+罗马音+翻译共存）时自动收拢，防止纵向溢出。
2. **辅歌词层级严控**：
   - 翻译与罗马音严格弱化，字体尺寸上限 20pt，且透明度绝不超过当前主行的 72%（翻译）与 64%（罗马音）。
   - 用户若在设置中调节了 `fontSize` 或 `assistantFontSize`，则以乘数形式叠加于上述基准，不得抹平 Active 与 Adjacent/Distant 之间的梯度差。
3. **元数据光学平衡**：
   - 歌曲标题最大行数限制为 2 行，超出采用截断。
   - 艺人与专辑在宽屏下以单行 `ViewThatFits` 并列展示，中间以 `·` 分隔；在窄屏或紧凑模式下无缝降级为双行紧凑堆叠 (`metadataStacked`)，不得产生字符挤压重叠。

---

## 2. Spacing Vocabulary (间距语汇与尺度阶梯)

Spotify Lyrics 采用以 **4pt 为基本模数 (Base Grid)** 的间距尺度阶梯，通过明确的语义命名分配界面间距，消除随意的无名常数。同时，承认并保留经过精细光学校准与窗口避让的特殊合理值。

### 2.1 标准间距语义阶梯 (4 ~ 48)

| Token | 数值 (pt) | 语义角色 (Semantic Role) | 典型应用场景 |
| :--- | :--- | :--- | :--- |
| **`Spacing.xxs`** | `4` | 微观微距 (Micro gap) | Ruby 字符与注音微距、多艺人逗号微距、进度条滑块微距、多行元数据纵向紧凑间距 (2~4) |
| **`Spacing.xs`** | `8` | 紧凑间距 (Compact padding) | 按钮内部图标与文字间隙、Toolbar 按钮互斥间距、全屏/悬浮歌词行基础间距、状态角标内边距 |
| **`Spacing.sm`** | `12` | 组件内间距 (Element gutter) | 弹窗及卡片内部元素间隙、封面与元数据微型模式间距、设置面板选项子项缩进 |
| **`Spacing.md`** | `16` | 标准边距 (Standard spacing) | 界面标准组件外边距、Header 标准内边距、紧凑分栏间隙、卡片圆角标准尺寸 (`card = 16`) |
| **`Spacing.lg_tight`** | `20` | 内容区块内距 (Block padding) | 内容区块内边距、Stage 控制条悬浮外框圆角 (`contentCornerRadius = 20`)、中等面板边距 |
| **`Spacing.lg`** | `24` | 歌词与分栏基准 (Row base) | 歌词基础行间距 (`lyricRowSpacing`)、双栏分栏间隙下限、小窗口边缘外边距 (`windowSmall = 24`) |
| **`Spacing.xl`** | `32` | 结构级间距 (Structural separation) | 封面与歌词栏常规间隙、中等窗口边缘外边距 (`windowMedium = 32`)、封面底部主标题纵向避让 |
| **`Spacing.canvas`**| `40` | 画布级留白 (Canvas margin) | Classic Canvas 水平内边距 (`canvasHorizontalPadding = 40`)、全屏歌词内边距基线 |
| **`Spacing.wide`**  | `48` | 宽幅展示间距 (Display wide gutter) | 焦点歌词模式两侧呼吸留白 (`geometry.size.width - 48`)、超大屏功能区大间距 |

### 2.2 合理特殊值定性与保护表

本规范明确以下特殊值属于**具备明确工程理由与光学视差校准的合法保留值**，不得机械整编为 4 的倍数：

| 特殊值 (pt) | 存在位置 | 存在理由与设计定性 | 阶段策略 |
| :--- | :--- | :--- | :--- |
| **`26`** | `immersiveColumnSpacing` / Fullscreen topBar padding top | 兼顾 macOS 交通灯按钮（红绿灯）垂直高度避让与封面/歌词视觉重心的黄金比例分割点 | **保留现状**，冻结不改 |
| **`28`** | `immersiveWindowPadding` / V3 垂直边距插值下限 | macOS 窗口标准标题栏高度 (28pt) 对称视觉延伸，保证顶部与底部视差对称 | **保留现状**，冻结不改 |
| **`34`** | Fullscreen 左右工具栏外边距 / 紧凑模式歌词可用宽扣减 | 大屏幕全屏边缘安全区（Safe Area），防止外围圆角显示器对极端文字造成裁切 | **保留现状**，冻结不改 |
| **`64`** | `Spacing.windowWide` / V3 宽屏横向边距插值上限 | 超宽屏（>1280pt）下防止内容直接贴靠左右屏幕边缘，通过双倍 32pt 保持舞台感 | **保留现状**，冻结不改 |
| **`72`** | `canvasVerticalPadding` | Classic 模式下顶部留白与底部播放器预留的大面积视觉沉浸空间 | **保留现状**，冻结不改 |
| **`7`** | `auxiliaryTopSpacing` | 原文汉字与下方翻译/罗马音之间的排版空隙，经多字体光学实测最不易被误认为新一行的距离 | **保留现状**，冻结不改 |

### 2.3 现状保留与后续收敛边界

- **本阶段严格保证**：不新增任何 Swift token 文件，不重构现有布局调用代码。
- **后续实现阶段（Future Implementation）收敛范围**：
  - 散落在特定私有 View 内的个别无名偏移常数（例如 `padding(.top, 18)`、`padding(.bottom, 22)`、`padding(.top, 9)` 等），在未来实现阶段收敛至 `Spacing.md + 2` 或最近的标准阶梯 `16/20/24`；
  - 动态插值算法（如 `interpolate(from: 32, to: 64)`）内部的连续端点予以保留，不作离散化破坏。

---

## 3. Material & Background Hierarchy (材质与背景层级)

Spotify Lyrics 坚持**封面驱动、深沉克制**的背景美学体系。背景不喧宾夺主，材质仅服务于增强文字可读性与控件交互认知，坚决反对全界面高亮玻璃或杂乱渐变。

```
┌─────────────────────────────────────────────────────────────────────────┐
│ [Layer 4] Temporary Elevated UI (Popovers, Sheets, Menus)              │
│           - High opacity material / Strong Drop Shadow (radius: 18)     │
├─────────────────────────────────────────────────────────────────────────┤
│ [Layer 3] Interactive Surface (Toolbar, Floating Controls, Progress)    │
│           - Ultra-thin frosted glass (white 0.08) / Keyline (white 0.12)│
├─────────────────────────────────────────────────────────────────────────┤
│ [Layer 2] Content Surface (Active/Inactive Lyrics, Artwork Stage)       │
│           - Transparent Canvas / Local Stage Veil / Optical Text Shadow │
├─────────────────────────────────────────────────────────────────────────┤
│ [Layer 1] Environment Base (Artwork Mesh Backdrop + Dark Gradient)     │
│           - Frozen Cover-Driven Palette / Multi-pass Gaussian / Dark Tint│
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.1 四层空间体系规范

1. **Layer 1: Environment Base (环境背景底色)**
   - **材质定义**：由实时曲目封面经过主色提取、多重高斯漫反射（`blur: 64 ~ 112pt`）并叠合 `backdropGradient` 构成。
   - **色调约束**：基底永远向深黑蓝沉降（顶部 `RGB(0.035, 0.045, 0.075)` 到底部 `RGB(0.025, 0.030, 0.055)`），饱和度钳制于 `0.78`，噪点轻微叠合 `0.035`。
   - **算法冻结**：**严格冻结现行 `normalizedBlur` 计算与着色着墨渲染链条**。禁止调整高斯模糊半径系数、明暗衰减曲线或材质着色通道。
2. **Layer 2: Content Surface (内容呈现层)**
   - **材质定义**：主歌词与主唱片封面直接悬浮于环境层之上，**严禁添加全屏卡片底板或矩形遮罩**，维持无边界视界。
   - **局部保护**：在 Stage 模式底部悬浮信息条处，使用 `.ultraThinMaterial.opacity(0.72)` 配以 `white.opacity(0.14)` 细描边与 `shadow(radius: 16)`，将控制条与流动背景分离。
3. **Layer 3: Interactive Surface (交互控制表面)**
   - **材质定义**：顶部工具栏（Search, Visual Tuning, Settings, Window Mode）与播放控制组件。
   - **样式规范**：背景采用超轻毛玻璃 `Color.white.opacity(0.08)`，外轮廓描边 `Color.white.opacity(0.12)`，圆角 `CornerRadius.control = 10`。
   - **交互显隐**：鼠标进入顶部 `96pt` 区域平滑淡入（`0.24s`），离开并静止 `3.0s` 后平滑隐匿至 `opacity: 0`，最大程度让位内容。
4. **Layer 4: Temporary Elevated UI (临时浮层与弹窗)**
   - **材质定义**：搜索面板（Search Popover）、设置中心（Settings Window）、对齐详情面板等。
   - **样式规范**：采用具备实体阻光特性的系统级材质或深色面板材质（`panelOpacity = 0.18` ~ 系统 Sheet 材质），并赋予深度空间投影（`Shadow.opacity = 0.20, radius: 18, y: 8`），与背景形成明确空间纵深。

---

## 4. Control-State Semantics (控件状态语义与验收边界)

本章定义交互控件在生命周期中的视觉状态语义与边界合同。**本阶段不设计任何完整新 Toolbar，仅建立状态渲染的验收基准**。

### 4.1 六大状态矩阵

| 状态 (State) | 背景表现 (Background) | 前景/图标色彩 (Foreground) | 描边 (Border / Keyline) | 几何变换 (Transform) | 视觉语义与验收边界 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Idle (闲置)** | `Color.white.opacity(0.08)` 或完全透明 | `secondaryText` (`white.opacity(0.64)`) | `Color.white.opacity(0.12)` 或无 | Scale: `1.0` | 融入环境，静默不抢眼，维持暗色秩序 |
| **2. Hover (悬停)** | `Color.white.opacity(0.14)` | `primaryText` (`white.opacity(0.92)`) | `Color.white.opacity(0.20)` | Scale: `1.0` | 平滑过渡 `0.15s easeInOut`，清晰反馈可点击性 |
| **3. Pressed (按下)** | `Color.white.opacity(0.22)` | 纯白 (`#FFFFFF` / `1.0`) | `Color.white.opacity(0.28)` | Scale: `0.96` 微物理压缩 | 瞬时响应，呈现触觉般的机械按压反馈 |
| **4. Selected / Active (激活)** | `Color.white.opacity(0.24)` 或 Accent 底色 | 纯白 (`1.0`) 或主题色 | `Color.white.opacity(0.32)` | Scale: `1.0` | 状态常驻标识（如歌词滚动锁定、穿透模式激活） |
| **5. Disabled (禁用)** | `Color.white.opacity(0.03)` | `mutedText` (`white.opacity(0.30)`) | 无或极弱描边 (`0.05`) | Scale: `1.0` | 降低可读性，鼠标变为不可点击指针，禁用命中测试 |
| **6. Keyboard Focus (焦点)** | 维持原有状态背景 | 维持原有前景 | 围绕控件边缘 2pt 距离的系统焦点环 (Focus Ring) | 无额外形变 | 符合 macOS Accessibility 标准，高对比可辨识 |

### 4.2 动效与过渡基线
- 状态切换动效必须统一采用标准界面过渡时长 `Motion.interfaceDuration = 0.24s` 或快捷微动效 `0.15s`。
- 在启用 **Reduce Motion** 时，所有 Hover/Pressed 的缩放形变全部归一为 `Scale: 1.0`，仅保留透明度微调。

---

## 5. Lyrics Readability Baseline (歌词可读性基线)

歌词是本产品绝对的核心内容。可读性基线旨在保证无论在何种极端封面、多语言排版或屏幕尺寸下，文字均具备第一眼可读性。

### 5.1 歌词行空间与景深分层

1. **Active 行 (当前播放句)**：
   - 不透明度：严格锁定为 `1.0`（结合用户设置微调下限为 0.85）；
   - 动态模糊：`blurRadius = 0`，文字呈现极致锐利边缘；
   - 字重：`.bold`；
   - 纵向留白：`verticalPadding` 为 `10pt`（双图层）~ `14pt`（单图层），强化当前行的垂直呼吸空间。
2. **Adjacent 行 (前一行与后一行，`distance = 1`)**：
   - 不透明度：`0.58`；
   - 动态模糊：`0.4pt`（极微量柔化，既维持可读性又脱离焦点焦点）；
   - 字重：`.semibold`；
   - 纵向留白：`6pt ~ 9pt`。
3. **Distant 行 (非邻近远端行，`distance >= 2`)**：
   - 不透明度：`0.36`；
   - 动态模糊：`1.6pt`（形成柔和景深）；
   - 字重：`.medium`；
   - 纵向留白：`5pt ~ 7pt`；
   - **远端辅助信息避让**：当用户开启 `hideDistantAuxiliary` 时，Distant 行自动隐藏翻译与罗马音，仅保留原文主歌词，极大地降低长文本屏幕滚动杂讯。

### 5.2 复合图层优先级 (Content Hierarchy)

同一歌词行内部，视觉能量依以下严密次序递减：
$$\text{原文 (Primary Lyric)} > \text{翻译 (Translation)} > \text{假名/注音 (Kana / Ruby)} > \text{罗马音 (Romaji)}$$

- **原文**：字号 `26 ~ 34pt`，颜色 `primaryText`。
- **翻译**：字号 `14 ~ 20pt`，颜色 `mutedText`，对比度略高于纯罗马音，满足跨语种理解的核心诉求。
- **注音 (Ruby)**：字号严格限制为主字的 `50% ~ 60%`（基准 55%，`11 ~ 18pt`），垂直紧贴汉字上沿，严禁与上一行文字发生物理交叉重叠。
- **罗马音**：字号 `14 ~ 20pt`，弱化为最低层级（`mutedText * 0.64`），作为发音参考。

### 5.3 长行换行与度量限制 (Measure & Line Wrapping)

- **最大阅读宽度**：严格遵守 `LyricsDesignTokens.readableLyricLineMaxWidth = 680pt`。
  - **设计依据**：人眼单次水平扫描的舒适阅读字数约为 40~60 个英文字符或 25~35 个中文字符。超宽屏幕若任由歌词单行无限延展，会导致用户频繁水平大幅扫视，大幅增加阅读疲劳度。
- **换行折叠规范**：
  - 超过可用宽度的长歌词允许自然折行（`fixedSize(horizontal: false, vertical: true)`）；
  - 折行行内间距为 `lineSpacing(2 ~ 4pt)`，不得破坏与下一首独立歌词行之间的 `lyricRowSpacing`（24~30pt）；
  - 假名注音行与主歌词在折行时必须以词素/Token 为单位整体换行，严禁注音与汉字拆散跨行。

### 5.4 极端封面环境下的可读性防护网

本基线严禁针对单一特定封面硬编码参数，必须在四类极端封面工况下均通过可读性自检：

```
[可读性防护网策略]
┌──────────────────┬───────────────────────────────────────────────────────┐
│ 封面工况          │ 视觉保护机制                                           │
├──────────────────┼───────────────────────────────────────────────────────┤
│ 1. 亮白 / 浅色封面 │ • 封面整体亮度压制：brightness(-0.02 ~ -0.10)          │
│                  │ • 暗角加深：vignetteIntensity = 0.42                  │
│                  │ • 歌词背景蒙版兜底：minimumLyricVeil = 0.22 (深黑半透遮罩)│
│                  │ • 文字对比度始终稳定在 >= 4.5:1 (WCAG AA 级标准)        │
├──────────────────┼───────────────────────────────────────────────────────┤
│ 2. 纯黑 / 极暗封面 │ • 底层冷调环境渐变启动：backdropGradient 提供微光漫反射 │
│                  │ • 消除死黑死寂感，文字依靠 primaryText (0.96) 呈现温和微发光│
├──────────────────┼───────────────────────────────────────────────────────┤
│ 3. 高饱和 / 杂色封面│ • 饱和度强力钳制：paletteSaturation 限制为 0.78       │
│                  │ • 超宽多重高斯模糊 (blur: 64 ~ 112pt) 打散高频视觉杂色  │
│                  │ • 严禁任何高饱和刺眼色块直接投射于歌词阅读轴线上        │
├──────────────────┼───────────────────────────────────────────────────────┤
│ 4. 单色 / 黑白封面 │ • 保持中性灰阶渐变层次                                │
│                  │ • 叠合精细噪点 (noiseIntensity = 0.035)，消除色阶断层    │
└──────────────────┴───────────────────────────────────────────────────────┘
```

---

## 6. Window Response Matrix (窗口响应矩阵)

Spotify Lyrics 支持多形态的窗口展现。本矩阵定义主窗口在连续伸缩过程中的几何响应规律，并界定全屏（Fullscreen）与悬浮窗（Floating）与主窗口的继承和独立边界。

### 6.1 主窗口 (Main Window) 尺寸四界限

1. **技术绝对下限 (Technical Minimum)**：`760 × 520 pt`
   - 窗口管理器拦截的物理硬边界，不可缩小至此界限以下。
2. **舒适体验下限 (Comfortable Reference)**：`800 × 600 pt`
   - 保证双栏排版、中型封面与歌词呼吸留白的最小推荐尺寸。低于此尺寸将逐渐收缩内边距。
3. **默认标准尺寸 (Default Standard)**：`1040 × 680 pt`
   - 绝大多数桌面屏幕上的开箱即用尺寸，呈现经典双栏比例。
4. **最大歌词阅读行宽 (Readable Measure Limit)**：`680 pt`
   - 无论窗口宽度拉伸至多宽（如 2560pt），歌词区域的文本排版宽度上限均锁定在 680pt，多余空间转为两侧优雅的外围留白。

### 6.2 主窗口五大响应象限 (Responsive Regimes)

```
             ┌─────────────────────────┬─────────────────────────┐
             │       Tall (高纵)        │       Wide (宽屏)       │
             │ width < 1080            │ width >= 1280           │
             │ height >= 750           │ aspectRatio >= 1.70     │
             │ • 纵向歌词空间极其充裕   │ • 双栏充分展开           │
             │ • 封面垂直居中           │ • 水平 padding 线性至 64│
  Height     ├─────────────────────────┼─────────────────────────┤
   Axis      │     Compact (紧凑)      │    Standard (常规)      │
             │ width < 900             │ 900 <= width < 1280     │
             │ height < 600            │ 600 <= height < 750     │
             │ • 封面缩减，分栏紧凑     │ • 经典双栏比例          │
             │ • 可选自动进入 Focus     │ • 黄金视觉参考          │
             ├─────────────────────────┴─────────────────────────┤
             │                   Short (扁平矮窗)                 │
             │ height <= 560 pt                                  │
             │ • 封面尺寸硬锁上限，预留 196pt 固定垂直高度给控制条 │
             │ • 防止进度条和元数据被顶出可视区                   │
             └───────────────────────────────────────────────────┘
                                   Width Axis
```

| 响应象限 | 触发几何判据 | 封面呈现策略 | 歌词栏排布策略 | 边距与间距行为 |
| :--- | :--- | :--- | :--- | :--- |
| **1. Compact (紧凑)** | `width < 900` 或 `height < 600` 或 `ratio < 1.25` | 封面尺寸缩至 `160 ~ 220pt`，或在开启 `lyricsFocus` 时隐匿封面转入单栏歌词 | 歌词列宽收至 `280 ~ 380pt`，行距收缩至 `24pt` | 水平 padding: `32pt`，分栏 gap: `24pt` |
| **2. Standard (标准)** | `900 <= width < 1280`，`600 <= height < 750` | 封面尺寸 `280 ~ 360pt`，保持正方形，位于左栏垂直居中偏上 | 歌词列宽 `380 ~ 520pt`，行距 `26 ~ 28pt`，视口锚定在 `0.47` 处 | 水平 padding: `32 ~ 48pt`，分栏 gap: `26pt` |
| **3. Wide (超宽屏)** | `width >= 1280` 或 (`width >= 1080` 且 `ratio >= 1.70`) | 封面尺寸舒展至 `380 ~ 480pt`，背景环境光大范围铺展 | 歌词列宽锁定在 `680pt` 上限，防止排版失焦 | 水平 padding 线性插值延展至 `64pt`，分栏 gap: `28pt` |
| **4. Tall (高纵向)** | `width < 1080` 且 `height >= 750` | 封面保持中等比例，元数据与进度条紧凑放置 | 歌词栏获得超高可视行预算（8~12行可见），阅读流动感最佳 | 垂直 padding 插值升至 `34pt` |
| **5. Short (扁平矮窗)** | `height <= 560` (逼近技术下限 520) | 封面高度强制受限：`max(1, availableHeight - 196)`，严防纵向溢出 | 歌词栏可视行压缩至 3~4 行，维持当前行居中 | 垂直 padding 压缩至 `28pt` |

### 6.3 全屏窗口 (Fullscreen) 的协同与独立关系

- **不是单纯放大的 Main**：
  - 彻底剥离主窗口的双栏硬分割、常驻侧边与管理工具；
  - 采用以文字为绝对主角的全局沉浸排版（歌词居中或偏左，宽度占屏幕 `58% ~ 66%`，内边距 `42pt`）；
  - 顶部与底部控制栏（曲名、播放/暂停、退出全屏）在无交互时彻底渐隐。
- **共享的核心资产**：
  - 共享 Typography 层级定义（主/辅歌词比例、字重、动态模糊算式）；
  - 共享 4pt Spacing 间距语汇；
  - 共享背景渲染内核与环境光着色策略；
  - 共享平滑切行策略与 Reduce Motion 规则。

### 6.4 悬浮歌词窗 (Floating) 的独立裁剪原则

- **当前歌词第一优先级**：
  - 专为桌面伴读场景设计，强调极轻、无打扰、可穿透；
  - 仅呈现当前播放行（及紧凑前/后各一行作为微上下文），不呈现大面积历史歌词流；
- **视觉层级裁剪**：
  - 不强行继承主窗口的大封面、播放进度条、复杂多栏元数据和设置面板；
  - 采用轻量毛玻璃或透明无底板（`transparentV2`），圆角规整为 `16pt`；
  - 仅在鼠标悬停时浮现微型锁定 (`lock`)、穿透 (`cursorarrow.slash`) 与关闭 (`xmark`) 控制钮。

---

## 7. Reduce Motion Inheritance (无障碍动态减弱继承)

本设计规范**无条件完整继承已验收的 Reduce Motion 合同行为**。在 macOS 开启「减弱动态效果」（Accessibility Reduce Motion）时，禁止任何形式的界面位移动效与形变动效，只保留极简的高级短淡化。

### 7.1 严格继承的既有验收行为表

| 界面要素 (Element) | 常规动态表现 (Normal Motion) | Reduce Motion 继承行为 (Strict Baseline) | 判定依据与实现映射 |
| :--- | :--- | :--- | :--- |
| **Lyric Viewport (歌词视口滚动)** | 0.44s 非弹簧平滑滚动曲线 (`viewportDuration: 0.44`) | **完全无位移动画 (0s)**，瞬间定位至目标行 | `viewportAnimation` 返回 `nil`，`proxy.scrollTo` 立即到位 |
| **Lyric Row Focus (行焦点聚焦)** | 0.30s 新行聚焦渐变 + 0.34s 旧行弱化 | **完全无字重/尺寸插值 (0s)**，属性立即就位 | `focusAnimation` 返回 `nil` |
| **Lyric Row Distance (距离重构)**| 0.34s 距离平滑过渡曲线 | **完全无位置/间距动画 (0s)**，位置立即更新 | `distanceAnimation` 返回 `nil` |
| **Lyric Blur Morph (模糊形变)** | `0.4pt ~ 1.6pt` 连续高斯模糊插值过渡 | **动态模糊彻底关闭 (`blur: 0`)**，所有文字锐利清晰 | `blur(radius: reduceMotion ? 0 : emphasis.blurRadius)` |
| **Generic Layout Signature** | 窗口拉伸/偏好设置修改时的布局插值 | **完全无布局插值动画 (0s)** | `transitionAnimation` 返回 `nil` |
| **Row Opacity (行不透明度淡化)** | 伴随焦点的 0.30s/0.34s 平滑演变 | **仅保留约 0.12s 的短淡化** (`easeInOut(0.12)`) | `LyricsTransitionPolicy.animation(reduceMotion: true)` |
| **Seek / Track Change (跳转与切歌)**| 立即定位 (`mode == .immediate`) | **保持绝对立即定位 (0s)**，旧行不参与任何动效 | 继承既有模式，无滞后追赶 |

### 7.2 架构约束
- **严禁建立第二套动效机制**：所有动效分支必须且只能由 `LyricsTransitionPolicy` 统一仲裁，严格服从 SwiftUI `@Environment(\.accessibilityReduceMotion)` 与系统 `NSWorkspace` 的真实状态，禁止各 View 内部私自编写带有弹簧或持续时间的本地 `.animation`。

---

## 8. Implementation Mapping Matrix (现有实现 → Visual Baseline 映射表)

本表将现有代码库实现与本 Visual Baseline 设计进行系统比对，明确三类状态：
1. **Already aligned / 保留**：现有实现已完全契合，冻结保留；
2. **Document-only clarification / 仅补规范**：现有代码行为有效，但此前缺乏明文标准，本次由文档固化为规范；
3. **Future implementation candidate / 以后才能改**：允许在后续独立实现阶段进行微调或收敛的候选项，本阶段绝不触动代码。

| 模块 / 视觉特性 | 现有实现所在文件 / 机制 | 当前实现状态 | Visual Baseline 定性与归类 | 处置策略与阶段边界 |
| :--- | :--- | :--- | :--- | :--- |
| **主歌词三级景深 (Active/Adj/Dist)** | `LyricsDesignTokens.lyricEmphasis` | 依据 distance 区分 1.0/0.58/0.36 不透明度与 0/0.4/1.6 模糊 | **Already aligned / 保留** | 现状符合可读性基线，冻结保护 |
| **主歌词响应式字号计算** | `LyricsDesignTokens.lyricEmphasis` | 宽度 520~1360 插值至 26~34pt | **Already aligned / 保留** | 现状高度自适应，冻结保护 |
| **辅歌词层级权重与透明度** | `LyricLineView` / `AppleMusicImmersiveV3LyricRow` | 翻译 0.72、罗马音 0.64、假名 0.85 递减 | **Already aligned / 保留** | 现状层级分明，冻结保护 |
| **四层材质与深色背景美学** | `AppleMusicImmersiveV3BackdropView` | 封面漫反射 + `backdropGradient` | **Already aligned / 保留** | 封面驱动美学冻结，严禁破坏 |
| **窗口尺寸四界限定义** | `LyricsDesignTokens.swift` | 760x520, 800x600, 1040x680, 680 max | **Already aligned / 保留** | 几何基线冻结，已有全局常量支撑 |
| **V3 连续自适应分栏几何** | `V3ResponsiveGeometry.adaptiveSplitMetrics` | 宽度 800~1360 连续插值内边距、分栏与间距 | **Already aligned / 保留** | 彻底消除跨阈值跳跃，冻结保护 |
| **Reduce Motion 0.12s 唯一淡化** | `LyricsTransitionPolicy` / `LyricLineView` | 禁用位移/blur/缩放，仅留 0.12s opacity | **Already aligned / 保留** | 已通过实机测试验证，冻结保护 |
| **控件 6 大状态语义 (Hover/Active等)** | 散见于各 ButtonStyle / ToolBar 局部实现 | 部分控件有 hover，但缺乏统一状态规范 | **Document-only clarification / 仅补规范** | 本次文档明确 6 态基准，不改代码 |
| **20/40/48pt 间距语义定位** | 现有 Spacing 包含 xxs~xl 及 windowToken | 代码中已存在 40/48 偶发使用但未入枚举 | **Document-only clarification / 仅补规范** | 文档确立 20/40/48 语义角色，不新增 token |
| **全屏与主窗口的解耦与共享规范** | `FullScreenLyricsView.swift` | 共享 LyricLineView 但独立布局 | **Document-only clarification / 仅补规范** | 文档界定共享与独立边界，不改全屏代码 |
| **悬浮歌词独立裁剪原则** | `FloatingLyricsView.swift` | 独立交互模式与材质，仅展示当前行 | **Document-only clarification / 仅补规范** | 文档确认轻量化原则，不强推主窗层级 |
| **极端封面可读性防护网策略** | `AppleMusicImmersiveV3BackdropView` | 现有饱和度钳制与暗角算法 | **Document-only clarification / 仅补规范** | 文档归纳四类极端封面验收准则 |
| **Toolbar 私有边距常数收敛** | `AppleMusicImmersiveV3WindowView` | 如 `padding(.top, 18)`、`trailing: 26` 等微距 | **Future implementation candidate / 以后才能改** | 本阶段绝不修改，留待未来 UI 重构统一 |
| **Stage 模式控制条局部圆角收敛** | `AppleMusicImmersiveV3WindowView` | 局部使用 `cornerRadius: 20` 与标准 card 16 的协调 | **Future implementation candidate / 以后才能改** | 本阶段不修改，后续 implementation 再议 |
| **设置面板与弹窗视觉规范整合** | `SettingsView.swift` 及各 Popover | 各面板局部内边距不完全一致 | **Future implementation candidate / 以后才能改** | 明确属于后续独立规划事项，本轮严禁改动 |

---

## 9. Boundary & Invariants (边界与冻结约束)

为维护架构纯洁度与历史稳定性，本视觉基线确立以下神圣不可侵犯的**冻结不变量**：

1. **Stage A 播放时钟与状态基线冻结**：
   - 严禁修改 `LyricsPresentationClock`、时间锚点同步、1.25s 轮询防回退窗口、真实 Seek / Track Reset 跳转语义。
2. **切行过渡模式语义冻结**：
   - 严禁修改 `LyricsLineTransitionMode`（`.softBoundary` 与 `.immediate`）的派发与判定机制；
   - 严禁向渲染层增加第二时钟、显示帧定时器（DisplayLink）或私有动画队列。
3. **背景算法与着墨管线冻结**：
   - 严禁修改 `AppleMusicImmersiveV3BackdropView` 中的 `normalizedBlur` 算式、多层模糊衰减级数与调色盘逻辑。
4. **禁止范围蔓延**：
   - 禁止修改任何 Swift 代码；
   - 禁止创建或重构 Toolbar / Settings 中心；
   - 禁止开启 Stage B；
   - 禁止建立全套臃肿的 Design System 框架，仅以轻量文档作为共享合同。

---

## 10. Architectural Principles & Non-Goals (架构原则与非目标)

### 10.1 架构原则
- **Content-First (内容第一)**：UI 元素是歌词的配角。背景、控件、边框必须后退，文字阅读体验永远置于第一优先级。
- **Shared Tokens, Distinct Surfaces (共享语汇，特化表面)**：Main, Fullscreen, Floating 共享同一套间距梯度、字体阶梯与过渡策略，但根据使用场景拥有独立的几何形态，不搞生搬硬套。
- **No Artificial Quantization (无人工量化)**：排版布局在连续窗口缩放中平滑线性插值，杜绝因离散断点切换引起的界面元素突兀跳跃。

### 10.2 非目标 (Non-Goals)
- 不在本阶段修改或提交任何 Swift 代码文件；
- 不重新设计或微调 V3 三种封面构图（Ambient, Stage, Classic）；
- 不引入第三方样式依赖库或重型设计系统；
- 不编写本规范之外的实施计划（Implementation Plan）。

---

## 11. Multi-Surface Relationship (多表面协同架构)

```
                       ┌─────────────────────────┐
                       │  LyricsDesignTokens     │
                       │  (Typography, Spacing,  │
                       │   Transition Policy)    │
                       └────────────┬────────────┘
                                    │ 共享基线与规范
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   Main Window    │       │ FullScreen View  │       │  Floating View   │
├──────────────────┤       ├──────────────────┤       ├──────────────────┤
│ • 双栏自适应布局 │       │ • 全局沉浸居中   │       │ • 极简伴读桌面条 │
│ • 封面 + 完整元数据│     │ • 自动隐匿工具栏 │       │ • 仅当前行+微上下文│
│ • 4类响应象限    │       │ • 弱化外部干扰   │       │ • 穿透与置顶交互 │
│ • 完整控制工具链 │       │ • 共享行排版规范 │       │ • 裁剪繁重元数据 │
└──────────────────┘       └──────────────────┘       └──────────────────┘
```

各表面分工明确、各司其职，通过统一的 `LyricsDesignTokens` 保持视觉血统纯正，杜绝各 Agent 或各表面开发者自行发明私有视觉参数。

---

## 12. Visual Baseline Contract & Verification Checklist (第 12 节：验收合同与逐项自检清单)

本节作为 Visual Baseline 设计文档的**最终只读验收合同**。后续阶段的任何实施或评审，均按本节所列条目逐一核对自检。

### 验收核对表

- [x] **12.1 Typography 规则覆盖与终值保护**：
  - 是否清晰定义了 Primary Lyric, Secondary Lyric (翻译/罗马音/假名/Ruby), Song Metadata (标题/艺人/专辑), Controls / Labels 等全部核心层级？（已在第 1 节完整定义）
  - 是否保护了现有响应式字号算式与光学视差终值，未做机械的硬编码抹平？（已在第 1.2 节明确要求）
- [x] **12.2 Spacing 4~48 阶梯与特殊值定性**：
  - 是否完整涵盖 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 的语义用途？（已在第 2.1 节表格详细定义）
  - 是否对现有 26 (分栏/避让), 28 (窗口基准), 34 (安全避让), 64 (超宽边距), 72 (画布留白) 明确定义为合理特殊值并予以保留？（已在第 2.2 节明确）
  - 是否清晰区分了「保留现状」与「后续实现收敛候选」，且未要求本阶段新增 Swift token？（已在第 2.3 节明确）
- [x] **12.3 四层 Material/Background 体系与背景算法冻结**：
  - 是否定义了 Environment, Content Surface, Interactive Surface, Temporary Elevated UI 四层物理空间体系？（已在第 3.1 节详细规范）
  - 是否明确写明封面驱动、深沉克制的背景美学冻结，严禁修改 `normalizedBlur` 及相关背景算法？（已在第 3.1 节与第 9 节加粗冻结）
- [x] **12.4 Control-State 6 大状态语义与验收边界**：
  - 是否完整覆盖 idle, hover, pressed, selected/active, disabled, keyboard focus 6 大交互状态？（已在第 4.1 节矩阵详列）
  - 是否严格限定于状态语义与验收边界，未越界设计完整新 Toolbar？（已在第 4 节声明边界）
- [x] **12.5 Lyrics Readability 规则、长行换行与极端封面防护**：
  - 是否清晰量化 active (1.0/blur 0), adjacent (0.58/blur 0.4), distant (0.36/blur 1.6) 的层级基准？（已在第 5.1 节规定）
  - 是否明确了 原文 > 翻译 > 假名/Ruby > 罗马音 的图层权重序列？（已在第 5.2 节规定）
  - 是否确立了 `680pt` 最大阅读行宽与自然换行规范？（已在第 5.3 节规定）
  - 是否在亮白、极暗、高饱和、黑白四类极端封面上建立了不依赖单张测试封面的可读性防护网？（已在第 5.4 节矩阵明确）
- [x] **12.6 Window 尺寸四界限、五象限与多表面协同**：
  - 是否准确定义了 Main Window 技术下限 (760×520)、舒适尺寸 (800×600)、默认尺寸 (1040×680)、最大歌词行宽 (680)？（已在第 6.1 节明确）
  - 是否系统定义了 Compact, Standard, Wide, Tall, Short 五大响应象限？（已在第 6.2 节详列）
  - 是否清晰说明 Fullscreen 不是单纯放大的 Main（共享规范、独立布局），Floating 遵循当前歌词优先并裁剪繁重元数据？（已在第 6.3 与 6.4 节界定）
- [x] **12.7 Reduce Motion 继承与已验收行为一致性**：
  - 是否严格继承了已验收的无 viewport 位移动画、无 scale morph、无 blur morph、仅保留约 0.12s opacity 短淡化、Seek/切歌立即定位等合同行为？（已在第 7.1 节详表明确）
  - 是否明确禁止建立第二套动画策略？（已在第 7.2 节加粗禁止）
- [x] **12.8 现有实现映射表三分类闭环**：
  - 是否提供了完整的映射矩阵，并严格区分 Already aligned / 保留、Document-only clarification / 仅补规范、Future implementation candidate / 以后才能改？（已在第 8 节以表格完整呈现 15 个关键特性）
- [x] **12.9 禁止项与纯文档约束**：
  - 是否未修改任何 App 代码、未触碰主仓库脏 checkout、未修改 Stage A 时钟、未修改切行、未开启 Stage B、未执行 push/PR？（已在第 9 节与全局严格恪守）

---

### 验收结论

**CONTRACT_SECTION_12_STATUS = PASS**

# Spotify Lyrics UI Visual Baseline Design Specification

- **Date**: 2026-09-03
- **Status**: Draft / Ready for Review
- **Document Path**: `docs/superpowers/specs/2026-09-03-ui-visual-baseline-design.md`
- **Scope**: Docs-only visual baseline specification. Does not mutate App Swift code, project configuration, tests, presentation clock, or background algorithms.

---

## 1. Typography Hierarchy (字体层级体系)

Spotify Lyrics 的字体层级以「歌词内容优先、元数据清晰克制、控件辅助静音」为核心原则。通过字号、字重、不透明度与动态模糊的组合，在暗色沉浸背景上建立清晰的视线焦点与阅读景深。

本规范严格**映射并保护现有代码直接证明的视觉终值**，不进行机械式的单字号硬编码统一，保留针对屏幕宽度、可见图层数（Layer Count）与光学视差的现有自适应调节。

现有 V3 歌词行与主要歌曲元数据在代码实现中普遍使用了系统 `.rounded` 设计（`Existing implementation / preserve`）。本基线尊重并保留这一既有事实；关于是否将 `.rounded` 强制确立为全 App 所有组件与窗口无例外的统一字体设计语言，定性为 `Future implementation candidate`，本阶段不作机械推演。

### 1.1 核心层级概览

| 层级名称 | 角色定位 | 基础字号 (pt) | 字重 (Weight) | 前景色 / 不透明度 | 动态表现 (Motion / Blur) | 状态定性 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary Lyric (Active)** | 当前焦点歌词原文 | 响应式 `26 ~ 34` (默认基准约 27~30) | `.bold` | `primaryText` / `1.0` | `blur: 0`，视线绝对焦点 | Existing implementation / preserve |
| **Primary Lyric (Adjacent)** | 上下相邻行歌词 (距离 `distance = 1`) | 相比 Active 略小 `2.0pt` (`24 ~ 32`) | `.semibold` | `primaryText` / `0.58` | `blur: 0.4pt`，近场伴读线索 | Existing implementation / preserve |
| **Primary Lyric (Distant)** | 远端非活跃歌词 (距离 `distance >= 2`) | 相比 Active 略小 `4.0pt` (`22 ~ 30`) | `.medium` | `primaryText` / `0.36` | `blur: 1.6pt`，大景深弱化背景 | Existing implementation / preserve |
| **Secondary Lyric (Translation)** | 歌词人工/AI 翻译 | 响应式 `14 ~ 20` (默认基准约 15~18) | `.regular` | `mutedText` / `effectiveOpacity * 0.72` | 随主行缩放与模糊，下沉 7pt (紧随罗马音时 3pt) | Existing implementation / preserve |
| **Secondary Lyric (Romaji)** | 日文罗马音辅助发音 | 响应式 `14 ~ 20` (默认基准约 15~18) | `.regular` | `mutedText` / `effectiveOpacity * 0.64` | 比翻译更低对比度，下沉 7pt | Existing implementation / preserve |
| **Secondary Lyric (Ruby / Kana)** | 假名注音 (Ruby) 与独立假名行 | Ruby: 主字号约 55% (`11 ~ 18`)；独立: `14 ~ 20` | Ruby: 主行同步；独立: `fontWeight` | `secondaryText` / `rubyOpacity` (`0.82 ~ 0.95`) | 汉字上方贴合注音，或作为独立辅助行 | Existing implementation / preserve |
| **Song Metadata (Title)** | 歌曲标题 (曲名) | 响应式 `18 ~ 30` (封面比例或紧凑模式) | `.bold` | 纯白 `#FFFFFF` / `1.0` | 柔和微投影（V3 沉浸模式） | Existing implementation / preserve |
| **Song Metadata (Artist / Album)** | 艺人名与专辑名 | `max(12, titleSize * 0.58)` (`12 ~ 17`) | V3: `.semibold`；标准: `.medium` | 艺人: `primaryText`；专辑: `secondaryText`；分隔符 `·`: white `0.35` | 单行优先，不足时纵向堆叠 | Existing implementation / preserve |
| **Controls / Labels** | 窗口控制、工具栏按钮标签 | 现有实现采用 `Typography.auxiliary` / `metadata` (`12 ~ 13pt`) | `.medium` | `secondaryText` 基准 | 跟随所在控件容器 | Existing implementation / preserve |
| **Transport Timecodes** | 播放进度时间码 (已播/总长) | `10 ~ 12` 等宽数字 (`.monospacedDigit`) | `.medium` | `mutedText` 基准 | 紧凑排布于进度条两侧 | Existing implementation / preserve |
| **Utility Badges / Tags** | 状态指示与辅助小标签 | `10 ~ 11` | `.medium` | `secondaryText` / `mutedText` | 局部胶囊或文本展示 | Existing implementation / preserve |

### 1.2 字体层级细则与保护约束

1. **主歌词自适应算式保全**：
   - 现有实现在 `LyricsDesignTokens.lyricEmphasis` 中依据视口宽度与可见图层计算：
     ```swift
     widthProgress = (min(max(availableWidth, 520), 1360) - 520) / 840
     layerPenalty = max(0, visibleLayerCount - 2) * 1.5
     activePrimary = min(34, max(26, 27 + widthProgress * 8 - layerPenalty))
     ```
   - **设计基线严格保留此动态计算逻辑**（`Existing implementation / preserve`）：宽窗下主字自然延展至 34pt，窄窗或多图层共存时自动收拢，防止纵向溢出。
2. **辅歌词层级严控**：
   - 翻译与罗马音严格弱化，尺寸不越过主歌词，且对比度显著低于主歌词原文（`Existing implementation / preserve`）。
   - 用户若在设置中调节了字号乘数，以现有实现乘数逻辑叠加，不得抹平 Active 与 Adjacent/Distant 之间的梯度差。
3. **元数据排版平衡**：
   - 歌曲标题最大行数限制为 2 行，超出截断。
   - 艺人与专辑在宽屏下以单行 `ViewThatFits` 并列展示，中间以 `·` 分隔；在窄屏或空间不足时无缝降级为双行紧凑堆叠 (`metadataStacked`)，不得产生字符挤压重叠（`Existing implementation / preserve`）。

---

## 2. Spacing Vocabulary (间距语汇与尺度阶梯)

Spotify Lyrics 采用以 **4pt 为基本模数 (Base Grid)** 的间距尺度语汇，通过语义定义分配界面间距。同时，承认并保留现有实现中经过精细光学校准与窗口避让的特殊合理值。

### 2.1 标准间距语义阶梯 (4 ~ 48)

| Token | 数值 (pt) | 语义角色 (Semantic Role) | 典型应用场景 | 状态定性 |
| :--- | :--- | :--- | :--- | :--- |
| **`Spacing.xxs`** | `4` | 微观微距 (Micro gap) | Ruby 字符与注音微距、多艺人逗号微距、进度条滑块微距、多行元数据纵向紧凑间距 (2~4) | Existing implementation / preserve |
| **`Spacing.xs`** | `8` | 紧凑间距 (Compact padding) | 按钮内部图标与文字间隙、Toolbar 按钮互斥间距、全屏/悬浮歌词行基础间距、状态角标内边距 | Existing implementation / preserve |
| **`Spacing.sm`** | `12` | 组件内间距 (Element gutter) | 弹窗及卡片内部元素间隙、封面与元数据微型模式间距、设置面板选项子项缩进 | Existing implementation / preserve |
| **`Spacing.md`** | `16` | 标准边距 (Standard spacing) | 界面标准组件外边距、Header 标准内边距、紧凑分栏间隙、卡片圆角标准尺寸 (`card = 16`) | Existing implementation / preserve |
| **`Spacing.lg_tight`** | `20` | 内容区块内距 (Block padding) | 内容区块内边距、Stage 控制条悬浮外框圆角 (`contentCornerRadius = 20`)、中等面板边距 | Document-only clarification / 仅补规范 |
| **`Spacing.lg`** | `24` | 歌词与分栏基准 (Row base) | 歌词基础行间距 (`lyricRowSpacing`)、双栏分栏间隙下限、小窗口边缘外边距 (`windowSmall = 24`) | Existing implementation / preserve |
| **`Spacing.xl`** | `32` | 结构级间距 (Structural separation) | 封面与歌词栏常规间隙、中等窗口边缘外边距 (`windowMedium = 32`)、封面底部主标题纵向避让 | Existing implementation / preserve |
| **`Spacing.canvas`**| `40` | 画布级留白 (Canvas margin) | Classic Canvas 水平内边距 (`canvasHorizontalPadding = 40`)、全屏歌词内边距基线 | Document-only clarification / 仅补规范 |
| **`Spacing.wide`**  | `48` | 宽幅展示间距 (Display wide gutter) | 焦点歌词模式两侧呼吸留白 (`geometry.size.width - 48`)、超大屏功能区大间距 | Document-only clarification / 仅补规范 |

### 2.2 合理特殊值定性与保护表

本规范明确以下特殊值属于**具备明确工程理由与光学视差校准的合法保留值**，不得机械整编为 4 的倍数：

| 特殊值 (pt) | 存在位置 | 存在理由与设计定性 | 阶段策略 |
| :--- | :--- | :--- | :--- |
| **`26`** | `immersiveColumnSpacing` / Fullscreen topBar padding top | 兼顾 macOS 交通灯按钮垂直高度避让与封面/歌词视觉重心的黄金分割点 | **Existing implementation / preserve** |
| **`28`** | `immersiveWindowPadding` / V3 垂直边距插值下限 | macOS 窗口标准标题栏高度 (28pt) 对称视觉延伸，保证顶部与底部视差对称 | **Existing implementation / preserve** |
| **`34`** | Fullscreen 左右工具栏外边距 / 紧凑模式歌词可用宽扣减 | 全屏边缘安全区，防止外围圆角显示器裁切文字 | **Existing implementation / preserve** |
| **`64`** | `Spacing.windowWide` / V3 宽屏横向边距插值上限 | 超宽屏（>1280pt）下防止内容贴靠屏幕边缘，通过双倍 32pt 保持舞台感 | **Existing implementation / preserve** |
| **`72`** | `canvasVerticalPadding` | Classic 模式下顶部留白与底部预留的大面积视觉沉浸空间 | **Existing implementation / preserve** |
| **`7`** | `auxiliaryTopSpacing` | 原文汉字与下方翻译/罗马音之间的排版空隙，经光学实测最不易被误认为新一行的距离 | **Existing implementation / preserve** |

### 2.3 现状保留与后续收敛边界

- **本阶段严格保证**：不新增任何 Swift token 文件，不重构现有布局调用代码。
- **关于现有私有偏置值（如 18, 22, 9 等无名数）**：
  - `Future implementation candidate — whether and how to consolidate must be decided case-by-case in a later implementation plan.`

---

## 3. Material & Background Hierarchy (材质与背景层级)

Spotify Lyrics 坚持**封面驱动、深沉克制**的背景美学体系。背景不喧宾夺主，材质仅服务于增强文字可读性与控件交互认知，坚决反对全界面高亮玻璃或杂乱渐变。

### 3.1 四层空间体系原则

1. **Layer 1: Environment Base (环境背景底色)**
   - **现有实现事实**：由实时曲目封面经过主色提取、高斯漫反射并叠合深黑蓝 `backdropGradient` 构成（`Existing implementation / preserve`）。
   - **算法冻结**：**严格冻结现行背景算法与 `normalizedBlur` 渲染管线**。本规范不增加新的着色通道、明暗衰减算法或自定义滤镜参数。
2. **Layer 2: Content Surface (内容呈现层)**
   - **现有实现事实**：主歌词与主唱片封面直接置于环境层之上，保持开放通透，无全屏矩形遮罩或卡片底板（`Existing implementation / preserve`）。
   - **局部容器**：Stage 模式底部悬浮控制条采用超薄毛玻璃材质局部衬托，将控制条与流动背景清晰分离（`Existing implementation / preserve in V3`）。
3. **Layer 3: Interactive Surface (交互控制表面)**
   - **现有实现事实**：顶部工具栏与播放控制组件采用半透明毛玻璃底色（`controlBackground` / `controlBorder`），圆角 10pt（`Existing implementation / preserve`）。
   - **V3 本地行为定性**：V3 窗口中鼠标悬停顶部 96pt 触发显示工具栏并在静止 3 秒后淡出的机制，定性为 `Existing implementation / preserve in V3`；是否将该行为推广为跨所有窗口与表面的全局工具栏规范，定性为 `Future implementation candidate`。
4. **Layer 4: Temporary Elevated UI (临时浮层与弹窗)**
   - **原则性要求**：搜索弹窗、设置中心与操作菜单作为临时浮层，须具备足够的阻光度与系统级投影，与背景形成明确空间层级。
   - **规范定性**：全 App 统一的弹窗材质与阴影统一参数属于 `Future implementation candidate`，本阶段不预设冻结值。

---

## 4. Control-State Semantics (控件状态语义与验收边界)

本章定义交互控件在生命周期中的视觉状态语义与验收边界。**本阶段不设计任何完整新 Toolbar，仅建立状态渲染的原则性验收基准**。

### 4.1 六大状态语义与验收原则

| 状态 (State) | 视觉表现原则 (Visual Principle) | 验收边界要求 (Acceptance Boundary) | 状态定性 |
| :--- | :--- | :--- | :--- |
| **1. Idle (闲置)** | 融入暗色环境，静默不抢眼，维持暗色秩序 | 使用现有控件背景（`controlBackground` / `controlBorder` 或无底色纯图标） | Existing implementation / preserve |
| **2. Hover (悬停)** | 提供清晰及时的悬停反馈 | 对比度或亮度提升（背景微亮或文字变亮），平滑过渡 | Document-only clarification / 仅补规范 |
| **3. Pressed (按下)** | 提供即时物理按压反馈 | 瞬时响应，明度加深或触觉式轻反馈；禁止夸张缩放变形 | Document-only clarification / 仅补规范 |
| **4. Selected / Active (激活)** | 清晰常驻的选中或激活指示 | 具有明确常驻高亮或状态图标，区分于闲置态 | Document-only clarification / 仅补规范 |
| **5. Disabled (禁用)** | 明确降低对比度与可读性 | 显著半透弱化，鼠标指针提示不可用，完全禁用交互与命中 | Document-only clarification / 仅补规范 |
| **6. Keyboard Focus (焦点)** | 明确的焦点指示 | 遵循 macOS Accessibility 标准焦点环，高对比且不遮挡内容 | Document-only clarification / 仅补规范 |

### 4.2 动效与跨控件统一
- 控件状态过渡动效遵循已有的 `Motion.interfaceDuration = 0.24s` 或快捷短动效（`Existing implementation / preserve`）。
- 全局通用 Control ButtonStyle 封装与具体 RGBA 色值统一属于 `Future implementation candidate`。

---

## 5. Lyrics Readability Baseline (歌词可读性基线)

歌词是本产品绝对的核心内容。可读性基线旨在保证无论在何种极端封面、多语言排版或屏幕尺寸下，文字均具备第一眼可读性。

### 5.1 歌词行空间与景深分层 (Existing implementation / preserve)

1. **Active 行 (当前播放句)**：
   - 不透明度：锁定为 `1.0`（结合用户偏好设置微调）；
   - 动态模糊：`blurRadius = 0`，边缘绝对清晰；
   - 字重：`.bold`；
   - 纵向留白：`verticalPadding` 为 `10pt ~ 14pt`，维持当前行视觉呼吸感。
2. **Adjacent 行 (前一行与后一行，`distance = 1`)**：
   - 不透明度：`0.58`；
   - 动态模糊：`0.4pt`（微量柔化，既维持可读性又脱离焦点）；
   - 字重：`.semibold`；
   - 纵向留白：`6pt ~ 9pt`。
3. **Distant 行 (非邻近远端行，`distance >= 2`)**：
   - 不透明度：`0.36`；
   - 动态模糊：`1.6pt`（形成柔和景深）；
   - 字重：`.medium`；
   - 纵向留白：`5pt ~ 7pt`；
   - **远端辅助信息避让**：开启 `hideDistantAuxiliary` 时，Distant 行隐藏辅歌词，降低长文本视觉杂讯。

### 5.2 复合图层优先级 (Content Hierarchy)

同一歌词行内部，视觉能量依以下严密次序递减（`Existing implementation / preserve`）：
$$\text{原文 (Primary Lyric)} > \text{翻译 (Translation)} > \text{假名/注音 (Kana / Ruby)} > \text{罗马音 (Romaji)}$$

- **原文**：字号 `26 ~ 34pt`，颜色 `primaryText`，居于第一视觉焦点。
- **翻译**：字号 `14 ~ 20pt`，颜色 `mutedText`，对比度显著高于罗马音。
- **注音 (Ruby)**：字号为主字的约 `50% ~ 60%`（基准 55%，`11 ~ 18pt`），垂直紧贴汉字上沿。
- **罗马音**：字号 `14 ~ 20pt`，弱化为最低对比度。

### 5.3 长行换行与度量限制 (Measure & Line Wrapping)

- **最大阅读宽度**：严格遵守 `LyricsDesignTokens.readableLyricLineMaxWidth = 680pt`（`Existing implementation / preserve`）。防止超宽屏下单行过长引发阅读扫视疲劳。
- **自然折行规范**：
  - 超过可用宽度的长歌词允许自然折行（`fixedSize(horizontal: false, vertical: true)`）；
  - 折行行内间距不得破坏与相邻独立歌词行之间的行距关系；
  - 假名注音行与主歌词在折行时必须以 Token 为单位整体换行，不得注音与汉字拆散分离。

### 5.4 极端封面环境下的可读性验收目标

本规范不设计任何新的背景防护算法，现有背景渲染管线保持完全冻结。本节仅确立针对真实曲库极端封面的**只读视觉验收目标**：

1. **亮色 / 高白封面 (Bright Covers)**：
   - 验收目标：歌词文本（白色系）与背景之间保持舒适反差，不得泛白失真，长时间阅读无眩光刺眼感。
2. **极暗 / 纯黑封面 (Very Dark Covers)**：
   - 验收目标：文字柔和温润，不产生刺眼眩光；背景保持深邃暗部层次而非死寂纯黑。
3. **高饱和 / 杂色封面 (High-Saturation / Vibrant Covers)**：
   - 验收目标：歌词主阅读区色彩平稳克制，背景色彩被打散柔化，不产生高频杂色冲击或色彩震颤干扰阅读。
4. **单色 / 黑白封面 (Monochrome Covers)**：
   - 验收目标：灰阶过渡平滑，文字层次与背景界限分明，无粗糙色阶断层。
5. **不针对单一测试封面硬编码**：
   - 验收目标：可读性表现须在多样化曲库封面上通用成立，严禁针对特定单曲封面微调代码参数。

---

## 6. Window Response Matrix (窗口响应矩阵)

Spotify Lyrics 支持多形态的窗口展现。本矩阵明确主窗口的核心界限与验收类别，并界定全屏与悬浮窗的协同和独立原则。

### 6.1 主窗口 (Main Window) 尺寸四界限 (Frozen Baseline)

以下四项几何界限为现有代码直接证明的冻结基准（`Existing implementation / preserve`）：

1. **技术绝对下限 (Technical Minimum)**：`760 × 520 pt` (`technicalMinimumMainWindowSize`)
   - 窗口管理器拦截的物理硬边界，不可缩小至此界限以下。
2. **舒适体验下限 (Comfortable Reference)**：`800 × 600 pt` (`comfortableMainWindowSize`)
   - 保证双栏排版、中型封面与歌词呼吸留白的推荐基准尺寸。
3. **默认标准尺寸 (Default Standard)**：`1040 × 680 pt` (`defaultMainWindowSize`)
   - 开箱即用标准尺寸，呈现经典双栏比例。
4. **最大歌词阅读行宽 (Readable Measure Limit)**：`680 pt` (`readableLyricLineMaxWidth`)
   - 无论窗口拉伸至多宽，歌词区域文本排版宽度上限锁定在 680pt，多余空间转为外围留白。

### 6.2 主窗口五大响应验收类别 (Responsive Regimes)

本基线将主窗口连续尺寸变化划分为五个验收类别（`Existing implementation / preserve`）：

| 验收类别 (Category) | 几何判定范围 | 封面与分栏行为 | 歌词排布表现 | 状态定性 |
| :--- | :--- | :--- | :--- | :--- |
| **1. Compact (紧凑)** | `width < 900` 或 `height < 600` 或 `ratio < 1.25` | 分栏收紧，封面尺寸随可用空间连续缩减；若用户开启了可选的 `automaticCompactLyricsFocus` 设置，则切换至单栏歌词焦点 | 歌词可用宽度收紧，行间距平滑收拢至 24pt | Existing implementation / preserve (无条件自动转 Focus 定性为 Future candidate) |
| **2. Standard (标准)** | `900 <= width < 1280`，`600 <= height < 750` | 封面比例平衡，居左上/居中排列 | 经典双栏比例，当前行视口平滑锚定 | Existing implementation / preserve |
| **3. Wide (宽屏)** | `width >= 1280` 或 (`width >= 1080` 且 `ratio >= 1.70`) | 封面舒展展开，环境光大范围铺展 | 歌词列宽受限于 680pt，外围留白自然延展 | Existing implementation / preserve |
| **4. Tall (高纵向)** | `width < 1080` 且 `height >= 750` | 封面居中，元数据紧凑 | 歌词视口获得充裕垂直行预算 | Existing implementation / preserve |
| **5. Short (扁平矮窗)** | `height <= 560` (逼近 520 极限) | 封面尺寸硬锁上限，预留垂直高度给控制条，防止控件溢出可视区 | 歌词可视行收缩，维持当前行焦点居中 | Existing implementation / preserve |

### 6.3 全屏窗口 (Fullscreen) 的协同与独立原则

- **不是单纯放大的 Main**：
  - 全屏属于独立的沉浸式展现，去除主窗口的常驻工具与双栏管理结构（`Existing implementation / preserve`）。
- **共享的核心资产**：
  - 共享 Typography 层级、Spacing 间距阶梯与 Transition 切行语义（`Existing implementation / preserve`）。
- **独立布局定性**：
  - 全屏具体的歌词列宽比例与安全边距属于当前独立布局实现（`Existing implementation / preserve in Fullscreen`）；是否建立跨主窗与全屏的统一比例 Token 属于 `Future implementation candidate`。

### 6.4 悬浮歌词窗 (Floating) 的独立裁剪原则

- **当前歌词第一优先级**：
  - 桌面伴读场景，以当前播放歌词为绝对重心，提供极轻、低干扰体验（`Existing implementation / preserve`）。
- **层级裁剪**：
  - 允许裁剪主窗口的大封面、播放进度条与复杂设置层级（`Existing implementation / preserve`）。
- **交互控件定性**：
  - 现有悬浮窗在交互模式下悬停浮现锁定、穿透与关闭按钮属于现有局部实现（`Existing implementation / preserve in Floating`）；跨表面通用的微型控制工具条规范定性为 `Future implementation candidate`。

---

## 7. Reduce Motion Inheritance (无障碍动态减弱继承)

本设计规范**严格继承已验收的 Reduce Motion 合同行为**。当系统开启「减弱动态效果」（Accessibility Reduce Motion）时，全面关闭物理位移与模糊形变，仅保留极简短淡化。

### 7.1 严格继承的既有验收行为表 (Existing implementation / preserve)

| 界面要素 (Element) | 常规动态表现 (Normal Motion) | Reduce Motion 继承行为 (Strict Baseline) | 现有实现对应机制 |
| :--- | :--- | :--- | :--- |
| **Lyric Viewport (歌词视口滚动)** | 0.44s 非弹簧平滑滚动曲线 | **完全无位移动画 (0s)**，瞬间定位至目标行 | `viewportAnimation` 返回 `nil` |
| **Lyric Row Focus (行焦点聚焦)** | 0.30s 新行聚焦渐变 + 0.34s 旧行弱化 | **完全无字重/尺寸插值 (0s)**，属性瞬间更新 | `focusAnimation` 返回 `nil` |
| **Lyric Row Distance (距离重构)**| 0.34s 距离平滑过渡曲线 | **完全无位置/间距动画 (0s)**，位置立即就位 | `distanceAnimation` 返回 `nil` |
| **Lyric Blur Morph (模糊形变)** | `0.4pt ~ 1.6pt` 连续高斯模糊插值过渡 | **动态模糊彻底关闭 (`blur: 0`)**，所有文字锐利清晰 | `blur(radius: reduceMotion ? 0 : ...)` |
| **Generic Layout Signature** | 窗口拉伸/偏好设置修改时的布局插值 | **完全无布局插值动画 (0s)** | `transitionAnimation` 返回 `nil` |
| **Row Opacity (行不透明度淡化)** | 伴随焦点的 0.30s/0.34s 平滑演变 | **仅保留约 0.12s 的短淡化** (`easeInOut(0.12)`) | `LyricsTransitionPolicy.animation(reduceMotion: true)` |
| **Seek / Track Change (跳转与切歌)**| 立即定位 (`mode == .immediate`) | **保持绝对立即定位 (0s)**，旧行不参与任何动效 | 继承既有模式，无滞后追赶 |

### 7.2 架构约束
- **禁止建立第二套动画策略**：动效决策必须完全由共享 `LyricsTransitionPolicy` 统一仲裁，严格服从 SwiftUI `@Environment(\.accessibilityReduceMotion)` 与系统真实状态。

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
| **控件 6 大状态语义 (Hover/Active等)** | 散见于各 ButtonStyle / ToolBar 局部实现 | 部分控件有 hover，但缺乏统一状态规范 | **Document-only clarification / 仅补规范** | 本次文档明确 6 态原则，不改代码 |
| **20/40/48pt 间距语义定位** | 现有 Spacing 包含 xxs~xl 及 windowToken | 代码中已存在 40/48 偶发使用但未入枚举 | **Document-only clarification / 仅补规范** | 文档确立 20/40/48 语义角色，不新增 token |
| **全屏与主窗口的解耦与共享规范** | `FullScreenLyricsView.swift` | 共享 LyricLineView 但独立布局 | **Document-only clarification / 仅补规范** | 文档界定共享与独立边界，不改全屏代码 |
| **悬浮歌词独立裁剪原则** | `FloatingLyricsView.swift` | 独立交互模式与材质，仅展示当前行 | **Document-only clarification / 仅补规范** | 文档确认轻量化原则，不强推主窗层级 |
| **极端封面可读性验收目标** | 多样化曲库封面实机表现 | 保证亮/暗/高饱和/黑白封面文字可读 | **Document-only clarification / 仅补规范** | 文档归纳四类极端封面验收目标，不发明新算法 |
| **Toolbar 私有边距常数收敛** | `AppleMusicImmersiveV3WindowView` | 如 `padding(.top, 18)`、`trailing: 26` 等微距 | **Future implementation candidate / 以后才能改** | Future implementation candidate — whether and how to consolidate must be decided case-by-case in a later implementation plan. |
| **Stage 模式控制条局部圆角收敛** | `AppleMusicImmersiveV3WindowView` | 局部使用 `cornerRadius: 20` 与标准 card 16 的协调 | **Future implementation candidate / 以后才能改** | Future implementation candidate — whether and how to consolidate must be decided case-by-case in a later implementation plan. |
| **全局 ButtonStyle 与控件样式封装** | 各视图内部局部样式修饰符 | 散见于各视图，缺乏全局通用封装 | **Future implementation candidate / 以后才能改** | Future implementation candidate — whether and how to consolidate must be decided case-by-case in a later implementation plan. |

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
│ • 5类响应象限    │       │ • 弱化外部干扰   │       │ • 穿透与置顶交互 │
│ • 完整控制工具链 │       │ • 共享行排版规范 │       │ • 裁剪繁重元数据 │
└──────────────────┘       └──────────────────┘       └──────────────────┘
```

各表面分工明确、各司其职，通过统一的 `LyricsDesignTokens` 保持视觉血统纯正，杜绝各 Agent 或各表面开发者自行发明私有视觉参数。

---

## 12. Visual Baseline Contract & Verification Checklist (第 12 节：验收合同与逐项自检清单)

本节作为 Visual Baseline 设计文档的**最终只读验收合同**。后续阶段的任何实施或评审，均按本节所列条目逐一核对自检。

### 验收核对表

- [x] **12.1 Typography 规则覆盖与终值保护**：
  - 是否清晰定义了 Primary Lyric, Secondary Lyric (翻译/罗马音/假名/Ruby), Song Metadata (标题/艺人/专辑), Controls / Labels 等核心层级？（已在第 1 节完整定义）
  - 是否保护了现有响应式字号算式与光学视差终值，未做机械的硬编码抹平？（已在第 1.2 节明确要求）
  - 是否未将未批准的全局 `.rounded` 规定为硬性统一规范，而是正确区分为现有事实与未来候选？（已在第 1 节及映射表明确定性）
- [x] **12.2 Spacing 4~48 阶梯与特殊值定性**：
  - 是否完整涵盖 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 的语义用途？（已在第 2.1 节表格详细定义）
  - 是否对现有 26 (分栏/避让), 28 (窗口基准), 34 (安全避让), 64 (超宽边距), 72 (画布留白), 7 (辅歌词空隙) 明确定义为合理特殊值并保留现状？（已在第 2.2 节明确）
  - 是否清晰区分了「保留现状」与「后续实现收敛候选」，且未要求本阶段新增 Swift token？（已在第 2.3 节明确）
  - 是否删除了预先指定的未来魔法数收敛规则，统一使用标准声明？（已在第 2.3 节与第 8 节严格采用 `Future implementation candidate — whether and how to consolidate must be decided case-by-case in a later implementation plan.`）
- [x] **12.3 四层 Material/Background 体系与背景算法冻结**：
  - 是否定义了 Environment, Content Surface, Interactive Surface, Temporary Elevated UI 四层空间原则？（已在第 3.1 节详细规范）
  - 是否明确写明封面驱动、深沉克制的背景美学冻结，严禁修改 `normalizedBlur` 及相关背景算法？（已在第 3.1 节与第 9 节加粗冻结）
  - 是否消除了背景算法内部冲突，未新增未经证明的背景算法参数？（已在第 3 节与第 5.4 节严格修正）
- [x] **12.4 Control-State 6 大状态语义与验收边界**：
  - 是否完整覆盖 idle, hover, pressed, selected/active, disabled, keyboard focus 6 大交互状态？（已在第 4.1 节矩阵详列）
  - 是否删除了未经验证的 pressed scale 0.96 及自造的具体 RGB/opacity 参数，改为原则性要求与验收边界？（已在第 4 节严格修正）
- [x] **12.5 Lyrics Readability 规则、长行换行与极端封面验收目标**：
  - 是否清晰量化 active (1.0/blur 0), adjacent (0.58/blur 0.4), distant (0.36/blur 1.6) 的层级基准？（已在第 5.1 节规定）
  - 是否明确了 原文 > 翻译 > 假名/Ruby > 罗马音 的图层权重序列？（已在第 5.2 节规定）
  - 是否确立了 `680pt` 最大阅读行宽与自然换行规范？（已在第 5.3 节规定）
  - 是否将极端封面章节纯粹聚焦于 4 类验收目标（亮/暗/高饱和/黑白及不依赖单张硬编码），未借此设计新算法？（已在第 5.4 节严格重构）
- [x] **12.6 Window 尺寸四界限、五象限与多表面协同**：
  - 是否准确定义了 Main Window 技术下限 (760×520)、舒适尺寸 (800×600)、默认尺寸 (1040×680)、最大歌词行宽 (680) 冻结界限？（已在第 6.1 节明确）
  - 是否系统定义了 Compact, Standard, Wide, Tall, Short 五大响应验收类别？（已在第 6.2 节详列）
  - 是否降级了未被当前代码证明的行为（如 Compact 自动转 Focus、Fullscreen 58%~66%/42pt、Floating 固定3行等）？（已在第 6 节严格降级）
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

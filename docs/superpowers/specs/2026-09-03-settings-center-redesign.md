# Settings Center Redesign — Design Contract

- **Status**: Ready for Review
- **Date**: 2026-09-03
- **Branch Baseline**: `antigravity/settings-center-audit` (`origin/main = b7f52e1acf6d1563795aa6815791dff08c3685b7`)
- **Document Path**: `docs/superpowers/specs/2026-09-03-settings-center-redesign.md`

---

## 1. Problem

当前 Spotify Lyrics 的设置中心（Settings Center）在演进过程中逐渐偏离了 macOS 原生应用偏好设置的标准职责与形态，存在以下核心问题：

1. **入口严重过密与扁平（Cognitive Overload）**：
   侧边栏平铺了多达 11 个分类（加上高级中隐藏的“体验版本库”共 12 个一级表面），缺乏大类聚合，列表垂直过长，导致用户寻找核心选项极为困难。
2. **非设置模块越界混杂（Domain Boundary Violation）**：
   “我的歌词库”（`PersonalLyricsLibraryView`，包含个人数据导出导入与第二层嵌套 `NavigationSplitView`）、“最近播放”（`ListeningHistoryView`，纯观察记录浏览）与“听歌统计”（`ListeningStatisticsView`，数据看板）本质上属于独立的数据浏览与分析功能，被硬塞进全局偏好设置。
3. **语言与文字语义割裂（Fragmented Typography Domain）**：
   “歌词显示”（Display）负责原文/翻译/罗马音与假名显示模式，而“读音与文字”（Reading）又单独负责假名/罗马音偏好、拼音、繁简转换与用户词典，导致同属于歌词排版和文字渲染的选项被生硬拆散。
4. **参数缺乏渐进式折叠（Flat Density & Form Fatigue）**：
   所有子项均采用长卡片（Grouped Form）直接平铺，专业调参项（如 AI Temperature、超时时间、自定义系统提示词）与核心连接凭据同等权重直出。
5. **标题栏裁切与排版缺陷（Header Clipping Defect）**：
   切换侧边栏分类时，多个页面的顶部大标题会漂移至窗口标题栏底边阴影下方并被裁切（`settings_audit_06_reading.png`、`settings_audit_07_spotify.png` 等），破坏了已冻结的 Visual Baseline。

---

## 2. Goals

1. **聚焦正统偏好设置**：
   Settings Center 只承担应用全局长期偏好与基础设施服务配置，剔除或桥接非设置重型模块。
2. **信息架构五大分类收敛**：
   一级核心分类精简收敛为 5 个直观大类：
   - **通用 (`General`)**
   - **歌词与文字 (`Lyrics & Text`)**
   - **服务与来源 (`Services & Sources`)**
   - **AI 翻译 (`AI Translation`)**
   - **高级与数据 (`Advanced & Data`)**
3. **渐进式展开（Progressive Disclosure）**：
   核心常用项（P0/P1）首屏直出，低频高级项与开发者参数（P2/P3）通过清晰的 Section 或系统 `DisclosureGroup` 折叠。
4. **修复顶部裁切缺陷**：
   在宿主容器层建立稳定统一的内容顶部安全内边距，确保切换任意分类时标题均清晰、完整可见。
5. **恪守架构与接口安全**：
   完全保留底层的 `AppSettingsStore`、`UserDefaults` 键名、`Keychain` 凭据存储、`SQLite` 数据库以及各业务 Manager，不改动任何运行时语义。

---

## 3. Non-Goals

1. 不在本轮重写 Settings 窗口外壳为顶部 TabBar（沿用稳定的 `NavigationSplitView` 侧边栏外壳）。
2. 不修改任何 `UserDefaults` 键名、`Keychain` 键名或 SQLite 数据库 schema。
3. 不重构或重新设计 `CurrentSongOperationsView`、`V3VisualTuningPopoverView` 或 Toolbar。
4. 不在本轮重写或删除“我的歌词库”、“最近播放”或“听歌统计”的原有实现，仅规范其入口层级与过渡形态。
5. 不引入跨多页面的复杂 Staging / Draft / Apply 事务模型（除特定凭据保存与破坏性确认外，常规选项继续维持修改即保存）。
6. 不增加全局性快捷键或新路由架构。

---

## 4. Current Ownership Diagnosis（归属诊断）

| 原分类 | 真实所有权属性 | 诊断结论 |
| :--- | :--- | :--- |
| **通用** (`General`) | Global Preference | 属于正统偏好；保留为主入口，并整合散落在各处的全局自动化开关。 |
| **我的歌词库** (`Library`) | Data Workstation | **非偏好设置**。具备完整增删改查、资产包导入导出且内嵌第二层双分栏，属于重型数据工具。本轮降级为“高级与数据”内的过渡桥接，不占一级偏好。 |
| **最近播放** (`History`) | Activity Log | **非偏好设置**。纯观察日志，无配置属性。降级为过渡桥接入口。 |
| **听歌统计** (`Statistics`) | Analytics Dashboard | **非偏好设置**。纯数据分析看板，无配置属性。降级为过渡桥接入口。 |
| **歌词显示** (`Display`) | Global Typography | 属于正统偏好；但与“读音与文字”同质，应合并为单一文字领域。 |
| **读音与文字** (`Reading`) | Global Language & Typography | 属于正统偏好；核心显示合并入“歌词与文字”，生成策略与词典作为渐进式折叠区。 |
| **Spotify** (`Spotify`) | Service & Credentials | 属于正统偏好（基础设施连接与授权凭据）；与歌词来源同构，应整合为“服务与来源”。 |
| **歌词来源** (`Sources`) | Provider Preference | 属于正统偏好；但“外部发现”属于临时工具，应收敛或后置。 |
| **数据与存储** (`Data`) | Maintenance & Storage | 属于高级维护（SQLite 备份与索引维护）；应与“高级”合并。 |
| **AI** (`AI`) | Service & Translation Defaults | 属于正统偏好；但当前 API 配置与专业 Prompt 调试平铺混杂，需做层级折叠。 |
| **高级** (`Advanced`) | Diagnostics & Fallback | 属于高级偏好；与数据维护合并为“高级与数据”。 |
| **体验版本库** (`ExperienceLibrary`) | Experimental Catalog | 属于实验性架构展示；继续后置在“高级与数据”内，不作为一级入口。 |

---

## 5. Final Information Architecture（最终信息架构）

最终侧边栏严格仅保留 **5 个一级核心偏好入口**。原非设置功能（我的歌词库、最近播放、听歌统计）不再占用侧边栏导航行，而是统一降级收纳于 `高级与数据 → 实用工具` 作为过渡桥接，确保侧边栏轻量、聚焦。

```
SettingsCenter
└── [侧边栏一级入口 / Five Direct Sidebar Categories]
    ├── 1. 通用 (General)
    ├── 2. 歌词与文字 (Lyrics & Text)
    ├── 3. 服务与来源 (Services & Sources)
    ├── 4. AI 翻译 (AI Translation)
    └── 5. 高级与数据 (Advanced & Data)
        └── [实用工具过渡桥接 / Transitional Tools Bridge]
            ├── 打开我的歌词库 (Personal Lyrics Library)
            ├── 查看最近播放 (Listening History)
            └── 查看听歌统计 (Listening Statistics)
```

> **说明**：侧边栏严格禁止出现 8~10 个平级入口。非设置模块通过“高级与数据”内部的实用工具区域保持可达，既杜绝功能失联，又维护了正统偏好设置的信息纯粹性。

---

## 6. Page-by-Page Content Contract（页面内容合同）

### 1. 通用 (`General`)

- **定位**：应用启动、切歌行为与全局窗口呈现策略。
- **Sections**：
  1. **主窗口**：
     - 默认主窗口布局（Picker：专辑沉浸 V2 / 经典放大 / 歌词专注 / 经典纯歌词）
     - 经典伴随呈现（Picker：自适应 / 沉浸分栏 / 歌词专注）
     - 小窗口自动进入歌词专注（Toggle）
     - 启动时恢复上次窗口状态（Toggle）
     - 主窗口保持置顶（Toggle）
  2. **悬浮歌词**：
     - 默认呈现版本（Picker）
     - 透明材质样式（Picker）
     - 悬浮窗透明度（Slider：45%~100%）
     - 默认交互状态（Picker：可编辑拖动 / 锁定展示 / 鼠标穿透）
     - 悬浮歌词保持置顶（Toggle）
  3. **自动化行为**：
     - 启动时自动连接 Spotify Desktop（Toggle）
     - 切歌后自动搜索歌词（Toggle）
     - 播放未排轴歌曲时自动尝试排轴（Toggle）
       *(语义定案：将原独立的“自动排轴”Section 收归至通用“自动化行为”，保持后台全局行为一致)*

---

### 2. 歌词与文字 (`Lyrics & Text`)

- **定位**：统一管理歌词在各窗口的语言层、假名/拼音注音、排版字号与读音策略。
- **Sections**：
  1. **语言层与排版（核心直出，默认展开）**：
     - 显示原文（Toggle）、显示翻译（Toggle）、显示罗马音（Toggle）、显示拼音（Toggle）
     - 假名显示模式（Picker：汉字上方注音 / 独立假名行 / 假名替换 / 隐藏）
     - 默认读音层（Picker：假名 / 罗马音）
     - 拼音格式（Picker：声调符号 / 声调数字 / 无声调）
     - 繁简转换（Picker：不转换 / 繁转简 / 简转繁）
  2. **字号与层级（核心直出，默认展开）**：
     - 当前歌词字号（Slider：14~42 pt）
     - 辅助文本字号（Slider：10~24 pt）
     - Ruby 假名大小（Slider：8~18 pt）
     - 非当前歌词透明度（Slider：15%~100%）
     - 远处歌词隐藏 Ruby 和罗马音（Toggle）
  3. **读音生成与用户词典（高级项，默认折叠 / DisclosureGroup）**：
     - 自动生成新歌词读音（Toggle）
     - 允许 AI 辅助候选（Toggle）
     - 不确定读音策略（Picker）
     - 用户词典列表与新增条目表单（保留原有本地词典管理）

---

### 3. 服务与来源 (`Services & Sources`)

- **定位**：管理播放器桌面连接、在线曲库 API 凭证与歌词提供方（Provider）调度链。
- **Sections**：
  1. **Spotify 播放控制与在线曲库**：
     - Desktop 连接状态（只读状态展示）
     - Web 在线曲库授权状态（只读状态展示）
     - Client ID 输入框与“保存”按钮
     - “授权 Spotify”、“刷新授权状态”、“断开授权”、“清除 Keychain Token”操作按钮
     - Dashboard 注册地址与本地回环监听地址提示（辅助说明）
  2. **歌词来源模式**：
     - 模式单选（RadioGroup：开放来源模式 / 扩展免费模式）
     - 实验模式风险提示 Banner
     - 恢复默认模式按钮
  3. **Provider 调度与优先级**：
     - Provider 列表（本地歌词、各网络源）
     - 启用状态 Toggle
     - 上移 / 下移调整搜索顺序按钮
  4. **外部检索工具（次级辅助工具，默认折叠 / DisclosureGroup）**：
     - 检索词输入框、复制检索词按钮、打开 Uta-Net/UtaTime/AWA 外部网页按钮。
     *(定案：移出主配置流，收纳于折叠区作为辅助备用手段)*

---

### 4. AI 翻译 (`AI Translation`)

- **定位**：AI 翻译基础设施服务、默认翻译风格与高级提示词工程。
- **Sections**：
  1. **服务配置（核心直出，默认展开）**：
     - 翻译引擎（Picker：Apple 系统 / OpenAI-compatible 等）
     - 兼容接口地址（Base URL，TextField）
     - 模型（Model，TextField + 刷新按钮 + 快捷选择 Picker）
     - API Key（SecureField，保存至 Keychain，提供“保存”与“清除”按钮）
     - 测试连接按钮与即时连通性反馈文本
  2. **翻译默认行为（核心直出，默认展开）**：
     - 目标语言（TextField，默认“简体中文”）
     - 默认提示词预设（Picker）
     - 自动翻译新歌词（Toggle）
  3. **高级模型参数与提示词管理（高级项，默认折叠 / DisclosureGroup）**：
     - 随机度（Temperature Slider：0.0~2.0）
     - 请求超时（Timeout Slider：5~600 秒）
     - 失败后的兜底策略（Picker）
     - 个人翻译风格选择与“管理个人翻译风格”弹窗入口
     - 自定义系统提示词（TextEditor）
     - “查看当前 Prompt 内容”只读预览入口（保留原有只读 Sheet）

---

### 5. 高级与数据 (`Advanced & Data`)

- **定位**：本地数据存储维护、运行期诊断、破坏性操作、实验性版本与实用工具过渡桥接。
- **Sections**：
  1. **SQLite 数据库与本地存储**：
     - 数据库路径、Migration 版本、曲目与歌词统计信息展示
     - 刷新统计、在 Finder 中显示、创建备份按钮
     - 重建本地歌词索引按钮
  2. **诊断与排错**：
     - App Build 版本与 Schema 版本展示
     - 打开日志目录按钮
     - 导出脱敏诊断摘要按钮
  3. **重置与危险操作**：
     - 重置窗口状态按钮（重置主窗口与悬浮窗口位置）
     - 清除所有歌词缓存（Destructive Button，带二次确认弹窗）
  4. **实用工具（过渡桥接 / Transitional Tools Bridge）**：
     - 打开我的歌词库（Button）
     - 查看最近播放（Button）
     - 查看听歌统计（Button）
     *(说明：Audit 确认这三项重型功能当前全 App 无其他入口；本轮在“高级与数据”内提供桥接入口保持可达，不新建独立窗口架构，不重新设计这三个业务模块)*
  5. **深入体验与实验版本（折叠 / 次级区域）**：
     - 打开“体验版本库”按钮
     - 设置中心外壳切换（若必须保留 V1/V2 切换）
     *(定案：移除纯文本占位的“Migration v2 规划”)*

---

## 7. Progressive Disclosure Contract（渐进式展开合同）

为了消除长表单视觉疲劳，严格规范展开状态规则：

| 页面 | 默认直接展示 (Default Expanded) | 默认折叠收纳 (Default Collapsed) |
| :--- | :--- | :--- |
| **通用** | 主窗口、悬浮歌词核心属性、自动化行为 | 无（总长度适中，直接分组清晰展示） |
| **歌词与文字** | 语言层开关、假名/拼音/繁简格式、全套字号与透明度滑块 | **读音生成与用户词典**（生成策略开关、AI 辅助候选、人工词典编辑列表） |
| **服务与来源** | Spotify 连接与 Web 授权凭据、歌词来源模式、Provider 排序 | **外部发现检索**（Uta-Net 等浏览器外链辅助框） |
| **AI 翻译** | 引擎/Base URL/Model/API Key、测试连接、目标语言、默认预设 | **高级调参与自定义 Prompt**（Temperature、超时、自定义 System Prompt、风格 Profile 管理） |
| **高级与数据** | SQLite 维护、重建本地索引、系统诊断导出、窗口重置、实用工具桥接 | **深入体验**（体验版本库跳转、设置中心版本切换） |

---

## 8. Preview / Apply Contract（预览与应用语义合同）

1. **Immediate Preference（常规偏好：即时持久化）**：
   - 所有 Toggle 开关、Picker 选择器、排版 Slider（字号、透明度）；
   - 用户操作即刻写入 `AppSettingsStore`，立即触发相关窗口（V3 主窗口、悬浮歌词）重绘并持久化至 `UserDefaults`；
   - 符合 macOS 原生偏好设置直觉，无需添加“应用/确定”按钮。
2. **Explicit Commit（敏感与破坏性操作：显式提交）**：
   - Spotify Client ID 保存：输入后点击“保存”写入；
   - AI API Key 保存：输入后点击“保存 API Key”写入系统 Keychain；离开页面清空内存草稿；
   - 危险操作（清空歌词缓存）：必须弹出 macOS 原生 Confirmation Dialog，确认后执行；
   - 重置窗口位置：点击按钮直接重置坐标。
3. **True Preview（真·临时预览：双状态分立）**：
   - 仅限“体验版本库”的呈现版本切换：
     - 提供“预览”（仅更新运行时 transient 状态，不落盘）；
     - 提供“取消预览”（恢复原状态）；
     - 提供“应用为默认”（持久化至设置）。
   - 普通偏好设置不引入 Staging 伪预览机制。
4. **Prompt Inspection（Prompt 预览语义纠正）**：
   - 按钮文案明确为“查看当前 Prompt 内容”；
   - 明确其为“发送给 LLM 的请求 JSON 只读检查”，而非“翻译后视觉效果预览”；
   - 弹窗顶部标明：“只读检查 · 不会向服务商发送请求，亦不影响已保存设置”。

---

## 9. Non-Settings Surfaces Treatment（非设置重型模块处理合同）

| 原 Surface | 真实属性 | 当前替代入口 | 本轮重整处理方案 (Redesign Treatment) |
| :--- | :--- | :--- | :--- |
| **我的歌词库** (`PersonalLyricsLibraryView`) | 个人本地歌词与资产维护工作台 | **无**（Settings 为当前全 App 唯一入口） | **从侧边栏彻底移除**；作为过渡桥接放入 `高级与数据 → 实用工具`（通过“打开我的歌词库”按钮唤起）。其内部包含的完整双栏/`NavigationSplitView` **明确记录为过渡期已知技术债务（transitional known debt）**，本轮不为了满足 Settings 规范重构其内部架构，后续由独立窗口设计承接。 |
| **最近播放** (`ListeningHistoryView`) | 运行期观察日志列表 | **无**（Settings 为当前唯一入口） | **从侧边栏彻底移除**；作为过渡桥接放入 `高级与数据 → 实用工具`（通过“查看最近播放”按钮唤起）。后续版本集成至主菜单“窗口”或状态栏。 |
| **听歌统计** (`ListeningStatisticsView`) | 播放数据统计看板 | **无**（Settings 为当前唯一入口） | **从侧边栏彻底移除**；作为过渡桥接放入 `高级与数据 → 实用工具`（通过“查看听歌统计”按钮唤起）。后续版本演进为独立仪表盘。 |
| **体验版本库** (`ExperienceLibrarySettingsView`) | 实验性呈现版本切换器 | 无（原深埋在高级） | 移出侧边栏；统一在“高级与数据”页面的“深入体验”Section 中通过按钮唤起。 |
| **Migration v2 规划** | 开发者架构路线占位文本 | 源码与文档 | **从用户设置界面完全移除**；不留无功能纯文本。 |

---

## 10. Visual / Layout Contract（视觉与布局合同）

1. **延续 Visual Baseline 材质**：
   - 设置中心使用 macOS 原生窗口背景与系统分组材质（`.formStyle(.grouped)`）；
   - 不引入 V3 歌曲封面的背景取色与高斯模糊；
   - 保持原生清晰可辨的输入框、滑块与选择器样式。
2. **卡片分组收敛（Anti-Card Fatigue）**：
   - 严禁“每一个微小配置项包装一个卡片”；
   - 单个页面卡片数控制在 2~4 个，通过明确的语义标题将相关项归拢于同一 Grouped Section。
3. **字体层级**：
   - Page Header Title：22~24pt Semibold（克制的大标题）；
   - Page Header Detail：12pt Secondary（辅助说明文案）；
   - Section Header：系统标准分组标题字阶；
   - 表单项文本：13pt Regular。
4. **排版间距**：
   - 页面主内容内边距统一为标准尺寸（水平 24~28pt，垂直 20~24pt）；
   - 控件组间距严格遵循 Visual Baseline 的 `8 / 12 / 16 / 24` 规范。

---

## 11. Header / Scroll Contract（标题安全区与滚动合同）

1. **根治顶部裁切 Bug**：
   - 统一在 `SettingsDetailView` 宿主容器层定义稳定的顶部安全内边距，消除外层硬编码 `padding(28)` 与内部 `Form` 自带 `NSScrollView` 顶部安全区的冲突；
   - 页面切换后，确保 Page Title 与 Subtitle 100% 完整可见，无任何 titlebar/toolbar 重叠与遮挡，且无错误的负向滚动偏移；
   - 根除切换页面后的削顶缺陷，不依赖逐页特殊的 padding hack；
   - 具体实现机制（是利用统一容器 inset 还是滚动偏移重置）留给 implementation plan 根据 SwiftUI 容器实机行为选择最小定向实现。
2. **首屏标题可见性**：
   - 每个一级分类进入时，Page Title 与 Subtitle 必须清晰、完整呈现在窗口标题栏下沿，不得被阴影削顶。

---

## 12. Window / Sidebar Contract（窗口与侧边栏合同）

1. **窗口几何尺寸**：
   - 默认尺寸维持推荐值：`860 × 580`；
   - 最小宽度：`780`，最小高度：`500`；
   - 支持自由缩放，右侧表单区域自适应居中或左对齐撑满，保证宽屏不突兀、窄屏不换行截断。
2. **侧边栏结构**：
   - 采用标准 `List(selection:)` + `.listStyle(.sidebar)`；
   - 侧边栏最小宽度 `180`，建议宽度 `200`；
   - **严格仅保留 5 个一级核心偏好入口**（通用、歌词与文字、服务与来源、AI 翻译、高级与数据），杜绝 8~10 个直接入口，保持侧边栏轻量清晰。
3. **导航分栏层级合同（NavigationSplitView Boundary Contract）**：
   - **单层约束严格适用于 5 个正式 Settings 页面**：通用、歌词与文字、服务与来源、AI 翻译、高级与数据这五个正式设置页面均只作为外层 `NavigationSplitView` 的 Detail 展示，严禁在此五类页面内再嵌套第二层 split navigation；
   - **过渡实用工具已知债务（Transitional Known Debt）**：`PersonalLyricsLibraryView` 内部已有的双栏/`NavigationSplitView` 仅通过“高级与数据 → 实用工具”作为过渡桥接访问，不属于设置中心布局重构范围；**明确记录为过渡期已知技术债务**，本轮不为了削足适履而重写歌词库，留待后续独立的 Library Window / Tools Surface 设计统一处理。

---

## 13. Accessibility Contract（无障碍合同）

1. **名称与标签**：
   - 所有侧边栏项目均包含文本标题与语义 SF Symbol 图标，对屏幕阅读器（VoiceOver）朗读明确无歧义；
   - 每个输入框（Client ID、API Key、Base URL）均具备可识别的无障碍标签与占位符；
   - 所有折叠展开控件（`DisclosureGroup`）朗读展开/折叠状态。
2. **全键盘访问 (FKA)**：
   - 键盘 `Tab` 键在表单各项间顺序流转，顺序与视觉阅读顺序（从上至下、从左至右）完全一致；
   - 按键与 Toggle 均可用 `Space` / `Return` 触发；
   - 破坏性按钮（清空缓存、清除 Token）具有显式 Destructive 语义提示。

---

## 14. Frozen Boundaries（严禁触碰边界）

本轮设置中心收敛严格遵守以下无触碰红线：
- [x] **严禁修改任何 Settings keys / schema**
- [x] **严禁触碰 Keychain 与 UserDefaults 底层键值设计**
- [x] **严禁修改 SQLite 表结构与迁移代码**
- [x] **严禁重新设计 Toolbar 或夺回已冻结在 CurrentSongOperationsView 的歌词版本/翻译操作**
- [x] **严禁修改播放控制、进度条、时钟或歌词平滑切行引擎**
- [x] **严禁修改 V3 三模式构图（Stage / Classic / Ambient）几何或背景算法**
- [x] **严禁全盘重构设置中心底层架构（保持现有 AppSettingsStore 架构）**

---

## 15. Candidate Implementation Sequence（实施候选序列）

本重整任务分解为 **5 个自包含、可单独验证的实施候选（Candidate）**，严格依序执行：

```
[Candidate 1: P0] 侧边栏 IA 收敛为 5 大核心偏好 + 根治标题栏裁切 Bug
       │
[Candidate 2: P1] 歌词与文字 (Lyrics & Text) 深度合并与排版层渐进折叠
       │
[Candidate 3: P1] 服务与来源 (Services & Sources) 整合与外部发现工具后置
       │
[Candidate 4: P1] AI 翻译页面渐进展开与 Prompt 预览语义明确化
       │
[Candidate 5: P2] 高级与数据 (Advanced & Data) 收敛、过渡工具桥接与无用内容剔除
```

- **Candidate 1 (P0) — 侧边栏信息架构收敛与标题安全区修复**：
  - 侧边栏严格收敛为 5 个核心分类（通用、歌词与文字、服务与来源、AI 翻译、高级与数据），移除所有非设置独立 sidebar rows；
  - 修复 `SettingsDetailView` 宿主层顶部安全内边距冲突，消除切页标题被削顶与负偏移 Bug；
  - 在 `Advanced & Data` 中为现有实用工具预留过渡路由/入口外壳；
  - 单独 commit，实机验证侧边栏纯净度与页面切换体验。
- **Candidate 2 (P1) — 歌词与文字（Lyrics & Text）合并**：
  - 合并原 `DisplaySettingsView` 与 `ReadingSettingsView` 为单一统一视图；
  - 高频字号与排版直出，高级读音策略与词典折叠收纳；
  - 单独 commit，实机验证字号联动与注音切换。
- **Candidate 3 (P1) — 服务与来源（Services & Sources）整合**：
  - 合并 `Spotify` 与 `LyricsSources`；
  - 保持 Desktop 状态与 Web 凭证清晰区分；
  - 将“外部发现”折叠收纳为次级工具；
  - 单独 commit，实机验证 OAuth 凭证与 Provider 调优。
- **Candidate 4 (P1) — AI 翻译页面渐进式折叠**：
  - 重构 `AISettingsView`，首屏突出 API 凭据、模型与测试连接；
  - 将 Temperature、超时、自定义 System Prompt 收进 DisclosureGroup；
  - 将 Prompt 预览说明明确为请求内容只读检查；
  - 单独 commit，实机验证 API 保存与参数微调。
- **Candidate 5 (P2) — 高级与数据（Advanced & Data）收敛与实用工具过渡桥接**：
  - 合并 `DataSettingsView` 与 `AdvancedSettingsView`；
  - 挂载“实用工具”过渡桥接入口（打开我的歌词库、查看最近播放、查看听歌统计）；
  - 挂载体验版本库入口；
  - 移除开发文档占位的“Migration v2 规划”纯文本；
  - 单独 commit，完成全设置中心最终集成与验收。

---

## 16. Acceptance Matrix（验收矩阵）

| 验收维度 | 验收合同标准 |
| :--- | :--- |
| **IA 收敛** | 侧边栏严格仅保留 5 个一级偏好入口；“我的歌词库/最近播放/听歌统计”无独立 sidebar row，统一通过 `高级与数据 → 实用工具` 保持可达。 |
| **标题裁切** | 切换至任意页面，Page Title 与 Subtitle 100% 完整可见，与标题栏下边缘无任何遮挡、重叠或负偏移，不依赖逐页 padding hack。 |
| **分栏约束** | 5 个正式设置页面均遵循单层 NavigationSplitView 规范；PersonalLyricsLibrary 内部已存 split view 作为已知过渡债务，不污染设置外壳。 |
| **显示与文字** | 歌词字号、翻译开关、假名注音模式、繁简转换在“歌词与文字”一站式调整，修改即刻在主窗口与悬浮窗口体现。 |
| **凭证安全** | Spotify Client ID 与 AI API Key 的显式保存与清除正常工作，Keychain 存取无降级。 |
| **渐进折叠** | AI 提示词与专业参数、读音高级策略、外部发现工具默认呈收起状态，点击可顺畅展开。 |
| **单曲边界** | 设置中心无任何当前单曲重新翻译、歌词编辑器跳转或版本强制切换逻辑，职责边界 100% 清晰。 |
| **工程质量** | Xcode Debug 编译 `** BUILD SUCCEEDED **`，0 警告；`git diff --check` 通过。 |

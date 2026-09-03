# Settings Center Redesign — Implementation Plan

- **Status**: Ready for Review
- **Date**: 2026-09-03
- **Branch Baseline**: `antigravity/settings-center-audit` (`origin/main = b7f52e1acf6d1563795aa6815791dff08c3685b7`)
- **Approved Design Contract**: `docs/superpowers/specs/2026-09-03-settings-center-redesign.md` (`a89448c7c81308b383240b2ca3006185890f77a0`)
- **Document Path**: `docs/superpowers/plans/2026-09-03-settings-center-redesign-implementation.md`

---

## 1. Baseline & Safety

- **Worktree**: `/private/tmp/spotifylyrics-settings-center-audit`
- **Branch**: `antigravity/settings-center-audit`
- **Baseline Git HEAD**: `b7f52e1acf6d1563795aa6815791dff08c3685b7`
- **Primary Checkout**: `/Users/apple/backup/sptifylyrics` 严格未修改、未触碰。
- **Swift Changes in this Plan Step**: **0** (纯方案制定，不含任何工程代码修改)。

---

## 2. Existing Code Map（真实源码与符号映射）

经定向源码审计，当前设置中心所有相关符号、文件与代码区间确认如下：

| Component / View | File Path | Line Range | Kind / Lifecycle | Current Backing & Routing State |
| :--- | :--- | :--- | :--- | :--- |
| `SettingsCategory` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L4–L36 | `private enum` | 12 个 case：平铺 11 个侧边栏导航行，`.experienceLibrary` 在列表过滤 |
| `SettingsRootView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L38–L91 | `struct View` | 宿主外壳，维护 `@State private var selection: SettingsCategory = .general` |
| `SettingsDetailView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L93–L117 | `private struct View` | 内部路由 Switch，根据 `category` 分发子视图，部分套用 `.padding(28)` |
| `SettingsPageHeader` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L119–L134 | `private struct View` | 页面标题容器（25pt Semibold + 12pt detail），置于各 Form 内部顶部 |
| `GeneralSettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L136–L230 | `private struct View` | 主窗口、悬浮歌词、启动与切歌、自动排轴表单 |
| `DisplaySettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L232–L304 | `private struct View` | 原文/翻译/罗马音开关、假名模式、字号/透明度滑块 |
| `SpotifySettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L305–L370 | `private struct View` | Spotify Desktop 状态、Web Client ID、OAuth 授权按键组 |
| `LyricsSourcesSettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L372–L512 | `private struct View` | 歌词来源模式（扩展免费/开放）、Provider 启用与排序、外部发现 |
| `DataSettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L513–L568 | `private struct View` | SQLite 数据库路径/统计、备份、Finder 展示、重建索引、清空缓存 |
| `AISettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L569–L854 | `private struct View` | 引擎、Base URL、Model、API Key (Keychain)、Prompt、Temp、超时 |
| `TranslationProfilesView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L855–L974 | `private struct View` | AI 个人翻译风格管理弹窗 Sheet |
| `TranslationPromptPreviewView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L976–L1005 | `private struct View` | Prompt 文本 JSON 检查 Sheet |
| `AdvancedSettingsView` | `SpotifyLyrics/Views/Settings/SettingsRootView.swift` | L1007–L1082 | `private struct View` | 诊断信息、重置窗口、打开体验版本库按钮、设置中心外壳切换、Migration 文本 |
| `ReadingSettingsView` | `SpotifyLyrics/Views/Settings/ReadingSettingsView.swift` | L1–L206 | `struct View` (独立文件) | 日语读音层、中文拼音、繁简转换、自动生成策略、用户词典维护 |
| `PersonalLyricsLibraryView` | `SpotifyLyrics/Views/Settings/PersonalLyricsLibraryView.swift` | L1–L847 | `public struct View` (独立文件) | 个人本地歌词库工作台，内嵌独立 `NavigationSplitView` 与 Toolbar |
| `ListeningHistoryView` | `SpotifyLyrics/Views/Settings/ListeningHistoryView.swift` | L1–L82 | `public struct View` (独立文件) | 运行期观察到的最近播放曲目列表与相对时间 |
| `ListeningStatisticsView` | `SpotifyLyrics/Views/Settings/ListeningStatisticsView.swift` | L1–L190 | `public struct View` (独立文件) | 听歌统计时间范围选择与排行数据看板 |
| `ExperienceLibrarySettingsView` | `SpotifyLyrics/Views/Settings/ExperienceLibrarySettingsView.swift` | L1–L374 | `struct View` (独立文件) | 呈现版本库双栏目录、卡片与预览/应用控制器 |

---

## 3. Design Constraints & Rules（设计约束与实施准则）

1. **五大分类绝对收敛**：
   侧边栏一级入口严格收敛为 5 个（通用、歌词与文字、服务与来源、AI 翻译、高级与数据），侧边栏禁止保留任何实用工具导航行。
2. **非设置模块过渡桥接**：
   我的歌词库、最近播放、听歌统计全 App 尚无其他入口，统一收归至 `高级与数据 → 实用工具` 桥接按钮保持可达，不破坏现有实现，明确记录为过渡已知债务。
3. **单层 NavigationSplitView 边界**：
   单层 split 约束严格约束 5 个正式 Settings 页面；`PersonalLyricsLibraryView` 内部已有的双栏作为过渡已知债务不在此轮重写。
4. **底层架构零侵入**：
   严禁修改 `AppSettingsStore`、UserDefaults keys、Keychain keys 或 SQLite schema。
5. **小步实施与原子验证**：
   每个 Candidate 自成独立 Commit，具备独立编译与实机验收闭环，验收通过后方可推进下一 Candidate。

---

## 4. Candidate 1 (P0) — Sidebar IA + Header Clipping Fix

### 目标
侧边栏严格收敛至 5 个核心偏好入口，杜绝 11 项平铺；彻底修复侧边栏切换时顶部标题被阴影削顶与负偏移的 Bug。

### A. 现有 Sidebar 定义与重构
- **现状**：`SettingsCategory` 包含 12 个枚举值，侧边栏 `ForEach` 仅过滤掉 `.experienceLibrary`，平铺了 11 个导航项。
- **重构方案**：
  在 `SettingsRootView.swift` 中将 `SettingsCategory` 重新定义为：
  ```swift
  private enum SettingsCategory: String, CaseIterable, Identifiable {
      // 5 个正式偏好一级入口 (Primary Sidebar Cases)
      case general = "通用"
      case lyricsAndText = "歌词与文字"
      case servicesAndSources = "服务与来源"
      case aiTranslation = "AI 翻译"
      case advancedAndData = "高级与数据"

      // 4 个过渡桥接隐藏目标 (Hidden Bridge Destinations, 不在侧边栏显示)
      case library = "我的歌词库"
      case history = "最近播放"
      case statistics = "听歌统计"
      case experienceLibrary = "体验版本库"

      static var primaryCases: [SettingsCategory] {
          [.general, .lyricsAndText, .servicesAndSources, .aiTranslation, .advancedAndData]
      }

      var id: String { rawValue }
      var systemImage: String { ... }
  }
  ```
  侧边栏列表严格仅遍历 `SettingsCategory.primaryCases`，侧边栏行数精确为 **5 项**。

### B. C1 阶段旧功能过渡编排 (Transition Orchestration)
为了确保 C1 提交后应用完整可用、0 功能丢失、0 placeholder，各分类在 C1 阶段的分发逻辑如下：
1. `.general`：直接渲染现有的 `GeneralSettingsView()`。
2. `.lyricsAndText`：临时组合现有的 `DisplaySettingsView()` 与嵌入式的 `ReadingSettingsView()`（垂直组合于单一视图中，为 C2 合并做平滑过渡）。
3. `.servicesAndSources`：临时组合现有的 `SpotifySettingsView()` 与 `LyricsSourcesSettingsView()`。
4. `.aiTranslation`：直接渲染现有的 `AISettingsView()`。
5. `.advancedAndData`：临时组合现有的 `DataSettingsView()` 与 `AdvancedSettingsView()`，并提前挂载 3 个实用工具跳转按钮。
6. 隐藏目标（`.library`, `.history`, `.statistics`, `.experienceLibrary`）：由 `SettingsDetailView` 承接分发，并带有标准“返回高级与数据”导航顶栏。
**结果**：C1 完成后，老用户所有 12 项功能 100% 依然可达，全链路 0 阻塞。

### C. Header Bug 根因定位与最小修复方案
- **根因分析**：
  1. `SettingsDetailView` 的 `Group { switch category { ... } }` 缺少 `.id(category)` 标识，导致切换分类时 SwiftUI 尝试原地 diff `Form` / `NSScrollView`，保留了上一页面的内部滚动偏移，导致新页面以错误的负向偏移切入；
  2. `SettingsDetailView` 对各子页面外部硬编码包装了 `.padding(28)`，而部分页面（如 `library`, `history`）未包装，外层 padding 与 `Form.grouped` 自带的安全区边距在导航切页时引起 AppKit 几何高度跳变；
  3. `SettingsPageHeader` 置于 Form 内部第一项，未脱离滚动层。
- **最小修复机制（Minimal Fix Strategy）**：
  1. 在 `SettingsDetailView` 中为 detail 根视图显式附加 `.id(category)`，强制切页时建立全新视图树与干净的零偏移滚动状态；
  2. 统一 Detail 宿主容器的外层边距策略，移除子 view 外部散落的 `padding(28)`，改由标准表单容器边距统领；
  3. 保持 `SettingsPageHeader` 语义清晰，验证切页后大标题在窗口工具栏下边缘完整呈现，零遮挡、零削顶。

---

## 5. Candidate 2 (P1) — Lyrics & Text Merge

### 目标
将分散在 `SettingsRootView.swift` 中的 `DisplaySettingsView` 与独立的 `ReadingSettingsView.swift` 深度合并为单一统一的 `LyricsAndTextSettingsView`。

### 结构与渐进折叠编排
- **视图归宿**：新建/演进 `SpotifyLyrics/Views/Settings/LyricsAndTextSettingsView.swift`，删除原有分散的 `DisplaySettingsView`，退休 `ReadingSettingsView.swift`。
- **Section 1: 语言层与排版（核心直出，默认展开）**：
  - 原文/翻译/罗马音/拼音显示开关 (`showOriginal`, `showTranslation`, `showRomaji`, `showPinyin`)
  - 假名显示模式 (`kanaDisplayMode`: 行内注音 / 独立行 / 替换 / 隐藏)
  - 默认读音层 (`japaneseRepresentationID`: 假名 / 罗马音)
  - 拼音格式 (`pinyinRepresentationID`: 声调符号 / 数字 / 无声调)
  - 繁简转换 (`scriptConversionID`: 不转换 / 繁转简 / 简转繁)
- **Section 2: 字号与层级（核心直出，默认展开）**：
  - 当前歌词字号 (`fontSize`: 14~42 pt)
  - 辅助文本字号 (`assistantFontSize`: 10~24 pt)
  - Ruby 假名大小 (`rubyFontSize`: 8~18 pt)
  - 非当前歌词透明度 (`opacity`: 15%~100%)
  - 远处歌词隐藏辅助文本 (`hideDistantAuxiliary`)
- **Section 3: 读音生成与用户词典（高级项，默认折叠 / `DisclosureGroup`）**：
  - 自动生成新歌词读音开关 (`automaticGeneration`)
  - 允许 AI 辅助候选开关 (`aiAssistedCandidate`)
  - 不确定读音策略 Picker (`uncertaintyPolicy`)
  - 用户人工词典维护列表与录入表单（完全复用原词典逻辑）

### Key 绑定保持
严格复用既有 `settings.displayPreferences` 与 `settings.readingSettings` 存储属性，0 键名修改，0 双写风险。

---

## 6. Candidate 3 (P1) — Services & Sources Merge

### 目标
将 `SpotifySettingsView` 与 `LyricsSourcesSettingsView` 合并为单一的 `ServicesAndSourcesSettingsView`，规范外部发现工具的次级收纳。

### 结构与分区
- **Section 1: Spotify 播放控制与在线曲库**：
  - Desktop 连接状态（只读辅助标签，不提供运行时恢复操作）
  - Web 在线曲库授权状态（只读标签）
  - Client ID 输入框与“保存”按钮（显式提交）
  - OAuth 授权、刷新、断开与清除 Token 按钮组
  - 开发者重定向地址与注册说明
- **Section 2: 歌词来源模式**：
  - 开放来源模式 vs 扩展免费模式单选
  - 实验模式免责提示 Banner
  - 恢复默认模式按钮
- **Section 3: Provider 调度与优先级**：
  - Provider 启用 Toggle 与 Up / Down 顺序调节
- **Section 4: 外部检索工具（次级辅助工具，默认折叠 / `DisclosureGroup`）**：
  - 检索词输入框、复制检索词、打开 Uta-Net/UtaTime/AWA 外部网页。

### 边界保护
Toolbar Provider Status 已经权威冻结为播放期运行时健康与恢复入口；本页面严禁侵入任何播放期重试、Mock Preview 或单曲恢复逻辑。

---

## 7. Candidate 4 (P1) — AI Translation Progressive Disclosure

### 目标
对 `AISettingsView` 实施渐进式折叠改造，纠偏 Prompt 预览文案，区分基础服务凭据与高级提示词工程。

### 结构与分区
- **Section 1: 服务配置（核心直出，默认展开）**：
  - 翻译引擎选择（Picker）
  - Base URL 与 Model 输入框 + 模型刷新按钮
  - API Key 安全输入框（SecureField）与“保存 API Key”、“清除 API Key”按钮
  - 测试连接按钮与即时连通性反馈
- **Section 2: 翻译默认行为（核心直出，默认展开）**：
  - 目标语言输入框
  - 默认提示词预设选择（Picker）
  - 自动翻译新歌词开关（Toggle）
- **Section 3: 高级模型参数与提示词管理（高级项，默认折叠 / `DisclosureGroup`）**：
  - 随机度滑块（Temperature: 0.0~2.0）
  - 请求超时滑块（Timeout: 5~600s）
  - 失败兜底策略（Picker）
  - 个人翻译风格选择与管理弹窗入口（`TranslationProfilesView`）
  - 自定义系统提示词编辑器（TextEditor）
  - Prompt 检查入口：文案修正为 **“查看当前 Prompt 内容”**，明确标注为发送给 LLM 的 JSON 请求只读检查，保留原有 `TranslationPromptPreviewView`。

---

## 8. Candidate 5 (P2) — Advanced & Data + Tools Bridge

### 目标
合并 `DataSettingsView` 与 `AdvancedSettingsView` 为单一统一的 `AdvancedAndDataSettingsView`，挂载实用工具过渡桥接，移除无用规划文本。

### 结构与分区
- **Section 1: SQLite 数据库与本地存储**：
  - 数据库路径、Migration 版本、数据量与大小统计展示
  - 刷新统计、Finder 打开、创建备份按钮
  - 重建本地歌词索引按钮
- **Section 2: 诊断与排错**：
  - App Build 与 Schema 版本
  - 打开日志目录按钮
  - 导出脱敏诊断摘要按钮
- **Section 3: 重置与危险操作**：
  - 重置窗口状态按钮（重置主窗口与悬浮窗口位置）
  - 清除所有歌词缓存（带原生确认弹窗的破坏性操作）
- **Section 4: 实用工具（过渡桥接 / Transitional Tools Bridge）**：
  - `Button("打开我的歌词库", systemImage: "books.vertical") { onOpenTool(.library) }`
  - `Button("查看最近播放", systemImage: "clock.arrow.circlepath") { onOpenTool(.history) }`
  - `Button("查看听歌统计", systemImage: "chart.bar") { onOpenTool(.statistics) }`
- **Section 5: 深入体验（高级折叠 / `DisclosureGroup`）**：
  - 打开“体验版本库”按钮 (`onOpenTool(.experienceLibrary)`)
  - 设置中心外壳切换 Picker（若仍保留经典 V1 选项）
- **文本剔除**：
  - 彻底删除 `Migration v2 规划` 的纯文本占位 Section。

---

## 9. Tools Bridge Routing Design（工具桥接路由设计）

### 方案选型与论证
- **被否决方案**：
  - 方案 A（新建 App 级 WindowRouter 或 Coordinator）：过度工程，违反 No-Go 红线；
  - 方案 C（在 SettingsRootView 内维护独立于 selection 的多状态机）：逻辑重复，增加状态不同步风险。
- **采纳方案（Option B：SettingsCategory 内置隐藏目标路由）**：
  - `SettingsCategory` 内置 4 个 hidden cases（`.library`, `.history`, `.statistics`, `.experienceLibrary`）；
  - 侧边栏仅展示 `primaryCases`（5 个偏好项）；
  - 当在 `Advanced & Data` 点击实用工具按钮时，直接将 `selection` 赋值为对应的 hidden case；
  - 在 `SettingsDetailView` 渲染工具视图的顶部附加统一样式的返回条：
    ```swift
    VStack(spacing: 0) {
        HStack {
            Button {
                selection = .advancedAndData
            } label: {
                Label("返回高级与数据", systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        Divider()
        // 工具自身视图
    }
    ```
  - 用户随时点击侧边栏 5 大类中的任意一项，亦可直接跳出工具返回对应设置页面。
  - **优势**：0 新增架构，0 全局耦合，代码完全内聚在 `SettingsRootView.swift`。

---

## 10. File-Level Changes（文件级变更规划）

| Candidate | Files Modified / Added / Deleted | Symbols Touched / Added / Removed | Runtime Behavior |
| :--- | :--- | :--- | :--- |
| **C1** | • `SettingsRootView.swift` | **Touched**: `SettingsCategory`, `SettingsRootView`, `SettingsDetailView`<br>**Added**: `primaryCases`<br>**Removed**: 侧边栏直接展示的非核心 case | 侧边栏收敛为 5 项；切页标题削顶消失；所有旧功能通过临时组合与隐藏目标完全可达。 |
| **C2** | • `LyricsAndTextSettingsView.swift` (新建)<br>• `SettingsRootView.swift`<br>• `ReadingSettingsView.swift` (退休/移除) | **Added**: `LyricsAndTextSettingsView`<br>**Removed**: `DisplaySettingsView`, 原 `ReadingSettingsView` | 歌词显示与读音合并，高频字号直出，读音策略与词典折叠收纳。 |
| **C3** | • `ServicesAndSourcesSettingsView.swift` (新建)<br>• `SettingsRootView.swift` | **Added**: `ServicesAndSourcesSettingsView`<br>**Removed**: `SpotifySettingsView`, `LyricsSourcesSettingsView` | Spotify 与 Provider 整合；外部发现工具折叠收纳；Toolbar 运行时职责不受影响。 |
| **C4** | • `SettingsRootView.swift` (或独立的 `AISettingsView.swift`) | **Touched**: `AISettingsView`<br>**Updated**: Prompt 检查文案与 DisclosureGroup | AI 核心凭证与默认直出；参数与提示词折叠；检查文案规范。 |
| **C5** | • `AdvancedAndDataSettingsView.swift` (新建)<br>• `SettingsRootView.swift` | **Added**: `AdvancedAndDataSettingsView`<br>**Removed**: `DataSettingsView`, `AdvancedSettingsView`, Migration 占位文本 | 高级与数据整合；挂载 3 个实用工具桥接与体验库；支持一键返回。 |

---

## 11. Verification Matrix（验证矩阵与测试用例）

| Candidate | 自动化验证命令 | 实机验收动作 | 截图凭证要求 |
| :--- | :--- | :--- | :--- |
| **C1** | `swift build -c debug`<br>`git diff --check` | 1. 启动 App 并按 `Cmd+,` 打开设置；<br>2. 验证侧边栏精准为 5 项；<br>3. 连续切换 5 个页面，验证顶部大标题 100% 完整可见、零阴影裁切。 | `settings_c1_sidebar_5_tabs.png`<br>`settings_c1_header_visibility.png` |
| **C2** | `swift build -c debug`<br>`git diff --check` | 1. 进入“歌词与文字”；<br>2. 调节字号与语言层 Toggle，确认主窗口实时生效；<br>3. 展开“读音生成与用户词典”，确认词典列表与新增表单正常工作。 | `settings_c2_lyrics_and_text.png`<br>`settings_c2_reading_expanded.png` |
| **C3** | `swift build -c debug`<br>`git diff --check` | 1. 进入“服务与来源”；<br>2. 校验 Spotify Desktop 状态只读正常；<br>3. 切换 Provider 顺序，验证配置即时生效；<br>4. 展开外部发现工具，校验外链按钮正常。 | `settings_c3_services_and_sources.png`<br>`settings_c3_discovery_expanded.png` |
| **C4** | `swift build -c debug`<br>`git diff --check` | 1. 进入“AI 翻译”；<br>2. 校验 API Key 存取与连通性测试；<br>3. 展开高级参数，校验 Temperature 滑块；<br>4. 点击“查看当前 Prompt 内容”，校验只读 Sheet 弹出。 | `settings_c4_ai_translation.png`<br>`settings_c4_prompt_inspection.png` |
| **C5** | `swift build -c debug`<br>`git diff --check` | 1. 进入“高级与数据”；<br>2. 验证 SQLite 路径与统计刷新；<br>3. 点击“打开我的歌词库”，校验歌词库打开且顶部有“返回高级与数据”按钮；<br>4. 校验“Migration v2”文本彻底不存在。 | `settings_c5_advanced_and_data.png`<br>`settings_c5_tools_bridge_opened.png` |
| **Integration** | `swift build -c debug`<br>`git diff --check` | 完整遍历全流程：5 大类偏好调节 -> 工具桥接进出 -> 凭据存取验证 -> 窗口缩放稳定性。 | `settings_final_overview.png` |

---

## 12. Commit Sequence（原子提交序列）

每个 Candidate 对应独立语义化 commit，严禁 squash：

1. **C1 (P0)**:
   `feat(settings): consolidate sidebar navigation and fix detail header visibility`
2. **C2 (P1)**:
   `feat(settings): merge lyrics display and reading preferences`
3. **C3 (P1)**:
   `feat(settings): consolidate Spotify and lyrics source settings`
4. **C4 (P1)**:
   `feat(settings): add progressive disclosure to AI translation settings`
5. **C5 (P2)**:
   `feat(settings): consolidate advanced data and transitional tool access`

---

## 13. Stop Conditions（停止与升级条件）

- 每一 Candidate 实施并完成实机验收测试后**立即停止并提交报告**；
- 严禁连续自主实施多个 Candidate；
- 必须在获得用户或 Reviewer 明确审查通过（`PASS`）后，方可启动下一 Candidate；
- 若实施过程中发现 SwiftUI `NavigationSplitView` 发生未预期的深度渲染异常，或需要引入全局架构，必须**立即停止并报告为 Relevant**，严禁自行扩展 Scope。

---

## 14. No-Go Scope Compliance（红线合规审查）

- [x] **0 UserDefaults key migration / 0 schema modification**
- [x] **0 Keychain credential schema changes**
- [x] **0 SQLite database schema or migration alterations**
- [x] **0 Toolbar or Current Song Operations interference**
- [x] **0 Playback, clock, or lyric layout algorithm changes**
- [x] **0 Window coordinator or global app router introduction**
- [x] **0 PersonalLyricsLibrary internal dual-pane rewrite** (transitional debt deferred)

# Other Windows & Secondary Surfaces Unification — Implementation Plan (P0 Directed Scope Revision)

- **Status**: Ready for Review (`OTHER_WINDOWS_P0_PLAN_REVISION_2=READY_FOR_REVIEW`)
- **Date**: 2026-09-04
- **Branch Baseline**: `antigravity/other-windows-audit` (`origin/main = cc4230fc771997796a819233270de783dc37f16b`)
- **Approved Design Contract**: `docs/superpowers/specs/2026-09-03-other-windows-unification-design.md` (`8702e5e37c6c426cd04ab701286457aa9f9f4875`)
- **Document Path**: `docs/superpowers/plans/2026-09-03-other-windows-unification-implementation.md`
- **Scope Allocation**:
  - **Active Targets (This Round)**:
    - **C1 (P0)**: Lyrics Editor 视觉收敛 (`LyricsEditorWindowView.swift`)
    - **C2 (P0)**: Lyrics Editor 全局入口 + 空白草稿与三态闭环 (`Main.swift`, `PlaybackState.swift`, `LyricsEditorModels.swift`, `LyricsEditorSessionController.swift`, `LyricsEditorWindowView.swift`)
  - **Deferred Post-P0 (本轮暂缓，不执行)**:
    - **C3 (P1)**: Library & Activity 统一工具窗口 (`personal-library-activity`)
    - **C4 (P1)**: 内嵌工具视图视觉平齐 (`Library`, `History`, `Statistics`)
    - **C5 (P2)**: MenuBar Popover 与辅助悬浮交互一致性

---

## 1. Baseline & Safety

- **Worktree**: `/private/tmp/spotifylyrics-other-windows-audit`
- **Branch**: `antigravity/other-windows-audit`
- **Git HEAD**: `70434709a6dbaddb8e7c2722cd10cc892e6afd09`
- **Main Dirty Checkout**: `/Users/apple/backup/sptifylyrics` (严格未修改、未触碰，零污染).
- **Swift Source Code Changes in this Plan Turn**: **0** (纯计划定向收口，不包含任何工程代码修改).
- **Previous Milestones Closed**:
  - `P0_R1_FINAL_REVIEW=PASS`
  - `P0_R2_FINAL_REVIEW=PASS`
  - `P0_FINAL_E2E_REVIEW=PASS`
  - `OTHER_WINDOWS_DESIGN_CONTRACT=PASS`

---

## 2. Design Decisions Carried Forward

From the approved Design Contract (`77bd6ad` + `8702e5e`):

1. **Lyrics Editor Identity & Geometry**:
   - Independent macOS productivity tool window (`Window("歌词编辑", id: "lyrics-editor")`).
   - Default dimensions: `1100 x 720` pt; Minimum dimensions: `980 x 620` pt. Standard titled window, traffic lights retained, not a borderless HUD.
2. **Lyrics Editor Global Entry & Tri-State Canvas Lifecycle**:
   - Primary menu entry: `Window` menu (`窗口 -> 歌词编辑器`, `Cmd+Shift+E`).
   - 彻底消除进入 `ContentUnavailableView` 的死胡同，根据真实播放与歌词状态无缝进入三种确切状态之一（见第 6 节详解）。
3. **Lyrics Editor Save Semantics & Keyboard Safety**:
   - 严格保留现有已验证的保存/应用闭环调用：
     - `editor.save()`
     - `editor.save(lockLyrics: true, lockTranslation: true)`
     - `lyricsEditorSession.onSaved`
     - `PlaybackState.applyLyricsEditorResult(...)`
   - 主保存按钮统一使用 `.buttonStyle(.borderedProminent)`，次要“保存并锁定”使用 `.borderless`。
   - 编辑器内全部 TextField 严格维持 macOS 标准 `Space` 键打字行为，严禁劫持 Space 作为播放快捷键。
4. **Deferred Surfaces (C3 / C4 / C5)**:
   - 个人歌词库、最近播放与听歌统计统一窗口（`personal-library-activity`）、MenuBar Popover 调整及辅助窗口交互策略全部标记为 `DEFERRED_POST_P0`，在本轮实施中不予执行。

---

## 3. Mandatory Source Preflight Findings

针对 C1 与 C2 的代码现状进行只读审查与精确事实核对：

### 3.1 现有保存与刷新链路（严格复用）
- **Window Scene 声明**：
  - 位于 `SpotifyLyrics/Main.swift:L79–84`：
    ```swift
    Window("歌词编辑", id: "lyrics-editor") {
        LyricsEditorWindowView()
            .environmentObject(playbackState)
            .environmentObject(settingsStore)
    }
    ```
- **核心保存回调**：
  - 在 `SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift:L204–206` 中调用：
    - `Button("保存人工版本") { editor.save() }`
    - `Button("保存并锁定", systemImage: "lock.fill") { editor.save(lockLyrics: true, lockTranslation: true) }`
  - 触发 `LyricsEditorSessionController.save(...)`（`Services/LyricsEditorSessionController.swift:L644–715`）。
  - 保存成功后，触发 `lyricsEditorSession.onSaved` 回调。
  - 在 `SpotifyLyrics/Services/PlaybackState.swift:L511–515` 绑定：
    ```swift
    lyricsEditorSession.onSaved = { [weak self] result, identity in
        self?.applyLyricsEditorResult(result, identity: identity)
    }
    ```
  - `applyLyricsEditorResult` 内部立即调用 `lyricsSession.adoptPersisted(...)`，实时播放界面立即采用并刷新。
  - **结论**：保存链路完整且完备，严禁新增保存模式或更改保存架构。

### 3.2 现有数据模型对空白与无曲目状态的支持度
- **State 1（有曲目 + 有歌词）**：
  - 现有 `state.canOpenLyricsEditor` 与 `state.prepareLyricsEditor()`（`PlaybackState.swift:L518–538`）天然支持。
- **State 2（有曲目 + 无歌词）**：
  - 现有 `state.canCreateManualLyrics` 与 `state.prepareBlankLyricsEditor()`（`PlaybackState.swift:L541–569`）已经完整存在！
  - 它直接使用当前真实 `currentTrack` 元数据（`title`, `artist`, `album`, `duration`）以及真实 `identity` 构建 `LyricsDocument(lines: [LyricLine(timestamp: 0, originalText: "")], source: .manualCreate)` 并通过 `lyricsEditorSession.beginNew(...)` 开启新会话。
- **State 3（无播放曲目）**：
  - 目前 `LyricsEditorDraft`（`LyricsEditorModels.swift:L91`）要求非空的 `public let identity: TrackIdentity`。
  - 目前 `LyricsEditorSessionController.save` 要求 `guard let draft, let track, let identity, let repository else { return }`。
  - 目前当无曲目时直接打开编辑器，`editor.draft == nil` 会导致停留在 `ContentUnavailableView("没有可编辑的歌词版本", ...)`。
  - 之前 Plan 曾草拟伪造 `"空白草稿"` / `"未知艺术家"` 字符串，此方案已被明确否决。
  - **结论**：必须在 `LyricsEditorDraft` 中将 `identity` 支持为 `TrackIdentity?`，并提供真正的 detached blank draft 模式，且在 detached 模式下天然阻止 `save()` 入库。

### 3.3 快捷键冲突排查
- `Cmd+Shift+E`（`⇧⌘E`）在整个工程中搜索：**0 处冲突**，完全可用。

---

## 4. Directed Candidate Graph & Sequencing

本轮交付严格收敛为前两个 P0 Candidate，C3/C4/C5 暂缓：

```
┌────────────────────────────────────────────────────────┐
│  Candidate 1 (P0): Lyrics Editor Visual Convergence    │
│  Target: LyricsEditorWindowView.swift                  │
│  Status: ACTIVE (实施准备中)                            │
└───────────────────────────┬────────────────────────────┘
                            │ (视觉基线就绪，不干扰逻辑)
                            ▼
┌────────────────────────────────────────────────────────┐
│  Candidate 2 (P0): Global Entry & Tri-State Blank Draft│
│  Targets: Main.swift, PlaybackState.swift, Models,     │
│           LyricsEditorSessionController, EditorView    │
│  Status: ACTIVE (实施准备中)                            │
└────────────────────────────────────────────────────────┘
                            │
                            │ [本轮交付终点，停止并等待验收]
                            ▼
══════════════════════════════════════════════════════════
  DEFERRED POST-P0 (交付时间有限，本轮暂缓执行):
  - Candidate 3: Library & Activity Unified Tool Window
  - Candidate 4: Embedded Tool Views Visual Polish
  - Candidate 5: MenuBar Popover & Auxiliary Consistency
══════════════════════════════════════════════════════════
```

- **Dependency Rules**:
  - C1 必须先完成（先收敛编辑器纯视觉样式与按钮层级，不破坏任何现有状态绑定）。
  - C2 紧随 C1 执行（接入全局菜单与三态生命周期，解决无曲目空草稿，彻底消灭死胡同）。
  - C2 完成后即刻停止，进行最终集成验收，不进入 C3。

---

## 5. Candidate 1 (P0) — Lyrics Editor 视觉收敛

### 5.1 Objective
对 `LyricsEditorWindowView` 进行视觉样式与布局收敛，应用 `LyricsDesignTokens` 设计语言，将主要保存操作视觉层级提升为 `.buttonStyle(.borderedProminent)`，统一深色背景与时间轴等宽字体排版。纯视觉收敛，零业务逻辑修改。

### 5.2 Scope & Files
- **唯一允许修改的文件**:
  - `SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift`
- **严禁触碰的文件**:
  - `Services/`, `Windows/`, `Persistence/`, `Views/MainWindow/`, `Views/Settings/`。
- **严格保留的代码行为**:
  - 保留全部 draft 双向绑定 (`editor.draft`)、撤销重做历史 (`editor.undo()`, `editor.redo()`)、部分保存确认提示 (`confirmPartialSave`)、辅助打字对齐 (`assistAutoAdvance`)。
  - 严格保留现有保存调用：
    - `Button("保存人工版本") { editor.save() }`
    - `Button("保存并锁定", systemImage: "lock.fill") { editor.save(lockLyrics: true, lockTranslation: true) }`
  - 严格保留 TextField 原生 macOS 文本输入行为，不劫持 Space 键。

### 5.3 Concrete Code Edits
1. **Window Background & Base Materials**:
   - 顶层容器使用 `Color(nsColor: .windowBackgroundColor)` 配合 `LyricsDesignTokens.Material.darkBase`，移除突兀的纯白硬边。
   - 歌词表格行交替底色收敛为微透明填充（`Color.primary.opacity(0.04)`）。
2. **Compact Tool Header**:
   - 高度统一至标准生产力工具条（`~48pt`，`.padding(.horizontal, 16)`, `.padding(.vertical, 10)`）。
   - 左侧（Leading）：主标题 `Text("歌词编辑").font(.headline.weight(.semibold))`，副标题展示曲目或状态（`.font(.caption).foregroundStyle(.secondary)`）。
   - 中间（Center）：状态文本（`editor.state.userFacingMessage` 或未保存变更指示符）。
   - 右侧（Trailing）：
     - 主操作：`Button("保存人工版本") { editor.save() }.buttonStyle(.borderedProminent)`
     - 辅助保存：`Button("保存并锁定", systemImage: "lock.fill") { editor.save(lockLyrics: true, lockTranslation: true) }.buttonStyle(.borderless)`
     - 实用操作保留：粘贴歌词、导入 TXT/LRC、导出原文/翻译、关闭。
3. **Timeline Row Typography**:
   - 时间戳输入框、行号及时间区间文字统一使用 `LyricsDesignTokens.Font.monospaced`（等宽字体），防止数字跳动。
   - 调整时间戳框与歌词文本框的水平间距，杜绝重叠。

### 5.4 Verification & Acceptance Criteria
- **静态检查**: `git diff --check` 必须 clean。
- **构建测试**: `xcodebuild Debug` 必须输出 `** BUILD SUCCEEDED **`。
- **运行时验证**:
  1. 从主窗口 `CurrentSongOperationsView` -> "编辑当前版本" 打开编辑器。
  2. 验证暗色背景材质、标题栏布局规整、“保存人工版本”高亮突出、等宽时间戳。
  3. 编辑歌词行内容，测试 `Cmd+Z` 撤销、`Cmd+Shift+Z` 重做正常。
  4. 点击“保存人工版本”，验证触发现有 `editor.save()` 且成功刷新播放界面。
- **证据记录**: 截图并保存 `other_windows_c1_editor_visual.png`。
- **停止条件**: C1 验收通过后立即停止，不要直接开始 C2。

---

## 6. Candidate 2 (P0) — Lyrics Editor 全局入口与空白草稿三态闭环

### 6.1 Objective
在系统菜单栏 `窗口` 中添加全局入口 `歌词编辑器`（快捷键 `Cmd+Shift+E`）。彻底解决无歌词或无播放时进入 `ContentUnavailableView` 的死路，准确实现以下**三种真实状态**，且在无播放曲目时使用真正的 detached blank draft，严禁伪造假数据。

### 6.2 三种真实运行状态架构设计

| 状态 | 触发前置条件 | 运行时行为 | 数据源与会话控制 | 保存与持久化语义 |
| :--- | :--- | :--- | :--- | :--- |
| **State 1: 有曲目 + 有歌词** | `hasLiveTrack == true` 且 `canOpenLyricsEditor == true` | 打开编辑器编辑当前歌词版本 | 调用现有 `state.prepareLyricsEditor()`，复用 `lyricsEditorSession.begin(...)`，载入已保存歌词行 | 点击“保存人工版本”调用现有 `editor.save()`，触发 `onSaved` 回调至 `PlaybackState.applyLyricsEditorResult` 闭环刷新 |
| **State 2: 有曲目 + 无歌词** | `hasLiveTrack == true` 且 `canCreateManualLyrics == true`（会话处于 `.noLyrics` / `.noSelection` / `.noMatch` / `.failed` / `.candidates`） | 使用当前曲目真实 metadata 打开空编辑器供用户创建歌词 | 调用现有 `state.prepareBlankLyricsEditor()`，直接使用 `currentTrack` 的真实 `title`、`artist`、`album`、`duration` 与真实 `identity`，复用 `lyricsEditorSession.beginNew(...)` | 点击“保存人工版本”调用现有 `editor.save()`，保存为真实曲目的 `manualCreate` 歌词版本，并在当前播放会话中立即应用生效 |
| **State 3: 无播放曲目** | `hasLiveTrack == false`（Spotify 未运行、未连接或停止播放） | 正常打开窗口，呈现真正的 **detached blank draft** 画布，绝不卡在不可用占位页 | 权威判定条件为 `hasLiveTrack == false`。进入真正的 detached 模式：`track = nil`, `identity = nil`, `title = nil`, `artist = nil`。必须使旧 session 失效或重置为独立草稿，严禁继续显示上一首歌曲的 draft / metadata，严禁伪造“空白草稿”或“未知艺术家” | **禁止保存到数据库**：`editor.canSave` 天然为 `false`，保存按钮处于禁用态（提示“需播放曲目以关联保存”）；防御性保证即使误触发保存，现有 guard（`guard let draft, let track, let identity, let repository else { return }`）也不会向 SQLite 写入孤立数据。用户可以进行基本的文本输入与编辑 |

### 6.3 State 3（无曲目 Detached Blank Draft）最小安全实现方案

为确保数据安全性，彻底杜绝无元数据假歌词落盘 SQLite，同时不破坏现有数据层强类型约束，采用以下最小改动方案：

1. **`LyricsEditorModels.swift` 调整**:
   - 将 `LyricsEditorDraft` 中的 `identity` 属性由强制非空改为可选：
     ```swift
     public struct LyricsEditorDraft: Equatable, Sendable {
         public let identity: TrackIdentity?
         public let title: String?
         public let artist: String?
         public let album: String?
         public let duration: TimeInterval?
         public let sourceVersionID: UUID
         public let sourceContentHash: String
         public let source: LyricsSource
         public var lines: [LyricsEditorLineDraft]
         // ...
     }
     ```
   - 增加独立的 detached 初始化方法：
     ```swift
     public init(
         lines: [LyricsEditorLineDraft] = [LyricsEditorLineDraft(originalText: "")]
     ) {
         self.identity = nil
         self.title = nil
         self.artist = nil
         self.album = nil
         self.duration = nil
         self.sourceVersionID = UUID()
         self.sourceContentHash = ""
         self.source = .manualCreate
         self.lines = lines
         self.savedLines = lines
     }
     ```
   - 在 `draft.document(...)` 中：若 `identity == nil`，则返回 `nil`（即 detached 状态无法生成持久化 `LyricsDocument`）。

2. **`LyricsEditorSessionController.swift` 调整**:
   - 增加 `beginDetached(...)` 方法：
     ```swift
     public func beginDetached(lines: [LyricsEditorLineDraft] = [LyricsEditorLineDraft(originalText: "")]) {
         generation &+= 1
         loadTask?.cancel()
         saveTask?.cancel()
         self.track = nil
         self.identity = nil
         self.sourceVersionID = UUID()
         self.sourceContentHash = ""
         self.sourceRevision = 0
         self.availableVersions = []
         self.availableTranslations = []
         self.selectedTranslation = nil
         self.pendingImport = nil
         self.pendingTextImport = nil
         self.message = nil
         self.isStale = false
         self.isNewSourceSession = false
         self.draft = LyricsEditorDraft(lines: lines)
         self.baseLyricsLines = lines
         self.baseTranslationLines = lines.map { _ in "" }
         self.state = .idle
     }
     ```
   - **保存安全防御机制**:
     - 现有 `LyricsEditorSessionController.save(...)` 内部第 645 行已有前置保护：
       ```swift
       guard let draft, let track, let identity, let repository else { return }
       ```
     - 在 detached 状态下，由于 `track == nil` 且 `identity == nil`，`canSave` 天然返回 `false`，任何调用均直接返回，**物理上绝对无法向 SQLite 写入任何数据**。

3. **`PlaybackState.swift` 触发收敛**:
   - 增加统一入口辅助函数 `prepareLyricsEditorForOpening()`，严格以 `hasLiveTrack` 作为 State 3 的权威判定条件：
     ```swift
     public func prepareLyricsEditorForOpening() {
         guard hasLiveTrack else {
             // State 3: 无播放曲目 (Authoritative: hasLiveTrack == false)
             // 必须明确进入 / 重建 detached blank draft，使旧 session 失效或重置为独立草稿，严禁继承上一首歌曲的旧 draft / metadata
             lyricsEditorSession.beginDetached()
             return
         }

         // hasLiveTrack == true: 由 canOpenLyricsEditor 与 canCreateManualLyrics 权威派发 State 1 / State 2
         if canOpenLyricsEditor {
             // State 1: 当前有播放曲目 + 已有歌词
             prepareLyricsEditor()
         } else if canCreateManualLyrics {
             // State 2: 当前有播放曲目 + 没有歌词 (允许人工创建)
             prepareBlankLyricsEditor()
         }
     }
     ```

4. **`LyricsEditorWindowView.swift` 渲染呈现**:
   - 头部标题与副标题渲染：
     ```swift
     Text(editor.draft?.title ?? (editor.draft?.identity == nil ? "歌词编辑" : state.currentTrack.title))
         .font(.title3.weight(.semibold))
     Text(editor.draft?.artist ?? (editor.draft?.identity == nil ? "未关联播放曲目" : state.currentTrack.artist))
         .font(.subheadline)
         .foregroundStyle(.secondary)
     ```
   - 保存按钮保护：
     ```swift
     Button("保存人工版本") {
         editor.save()
     }
     .buttonStyle(.borderedProminent)
     .disabled(editor.draft?.identity == nil || !editor.canSave)
     .help(editor.draft?.identity == nil ? "当前未关联播放曲目，无法直接保存到数据库；请先在 Spotify 播放歌曲" : "")
     ```
   - 消除 `ContentUnavailableView`：只要 `editor.draft != nil`（包括 detached 空草稿），均统一渲染 `editorBody(draft)`，用户直接面对可编辑草稿。

5. **`Main.swift` 菜单绑定**:
   - 在 `CommandMenu("窗口")` 中添加：
     ```swift
     Button("歌词编辑器") {
         playbackState.prepareLyricsEditorForOpening()
         openWindow(id: "lyrics-editor")
     }
     .keyboardShortcut("e", modifiers: [.command, .shift])
     ```

### 6.4 Scope & Files
- **允许修改的文件范围（共 5 个文件）**:
  1. `SpotifyLyrics/Editor/LyricsEditorModels.swift`（支持 `identity: TrackIdentity?` 与 detached init）
  2. `SpotifyLyrics/Services/LyricsEditorSessionController.swift`（增加 `beginDetached`）
  3. `SpotifyLyrics/Services/PlaybackState.swift`（增加 `prepareLyricsEditorForOpening`）
  4. `SpotifyLyrics/Views/Editor/LyricsEditorWindowView.swift`（UI 对接三态与禁用未关联保存）
  5. `SpotifyLyrics/Main.swift`（系统菜单 `窗口 -> 歌词编辑器`）
- **严禁触碰的文件**:
  - `SQLiteLyricsRepository.swift`、网络 Provider、Main V3 窗口、Toolbar、Settings、PresentationClock。

### 6.5 Verification & Acceptance Criteria
- **静态检查**: `git diff --check` passes cleanly。
- **构建测试**: `xcodebuild Debug` passes cleanly。
- **三态运行时验证**:
  1. **验证 State 1（当前有曲目 + 已有歌词）**: Spotify 正在播放已存在歌词的歌曲，按 `Cmd+Shift+E`，编辑器打开并载入当前歌词版本，可编辑，点击“保存人工版本”能够持久化并刷新主界面。
  2. **验证 State 2（当前有曲目 + 无歌词）**: Spotify 正在播放一首没有歌词的歌曲（无歌词恢复态），按 `Cmd+Shift+E`，编辑器使用该歌曲真实元数据打开空草稿，输入歌词并保存，验证保存为该真实曲目的人工版本。
  3. **验证 State 3（无播放曲目 Detached Blank Draft，严格收敛至 Contract 承诺最小集）**:
     - 可以在无播放曲目时（`hasLiveTrack == false`）通过 `窗口 -> 歌词编辑器` 或 `Cmd+Shift+E` 成功打开
     - 呈现真正的 detached blank draft 可编辑画布，绝不卡在 `ContentUnavailableView` 占位页
     - 严禁继承上一首歌曲的任何残留信息（旧 draft / metadata 彻底失效重置）
     - 不伪造 title / artist / identity（头部副标题明确指示未关联播放曲目，杜绝“空白草稿”或“未知艺术家”伪造字段）
     - 明确说明 Save 按钮处于禁用状态（`canSave == false`）
     - 防御性保证：即使误触发保存，现有 guard（`guard let draft, let track, let identity, let repository else { return }`）也不会向 SQLite 写入孤立数据
     - 用户可以进行基本的文本输入与编辑
     *(注：删除未在 Contract 中承诺的 TXT/LRC 导入、时间轴工具及 LRC 导出等强制验收要求)*
  4. **验证菜单项**: 检查系统菜单栏 `窗口` 下出现 `歌词编辑器`，快捷键标注为 `⇧⌘E`。
- **证据记录**:
  - `other_windows_c2_state1_active.png`
  - `other_windows_c2_state2_blank_track.png`
  - `other_windows_c2_state3_detached.png`
  - `other_windows_c2_menu_shortcut.png`
- **停止条件**: C2 完整通过并记录证据后立即停止，不得擅自启动 C3。

---

## 7. Candidate 3 (P1) — [DEFERRED POST-P0 / 暂缓执行]

- **Status**: `DEFERRED_POST_P0`
- **原计划范围**: Library & Activity 统一工具窗口声明及菜单入口。
- **暂缓理由**: 当前交付时间有限，产品核心收敛聚焦于已通过全量 E2E 的主干与 Lyrics Editor 生产力闭环。工具窗口归并属于二级管理界面，本轮不予启动。

---

## 8. Candidate 4 (P1) — [DEFERRED POST-P0 / 暂缓执行]

- **Status**: `DEFERRED_POST_P0`
- **原计划范围**: 歌词库、最近播放与听歌统计三内嵌视图视觉收敛。
- **暂缓理由**: 依赖 C3 统一容器窗口，随着 C3 暂缓而同步延后，本轮不予启动。

---

## 9. Candidate 5 (P2) — [DEFERRED POST-P0 / 暂缓执行]

- **Status**: `DEFERRED_POST_P0`
- **原计划范围**: MenuBar Popover 280pt 调整与辅助窗口交互层级微调。
- **暂缓理由**: MenuBar 与 Auxiliary 悬浮窗口已在 P0 Final E2E 中通过可用性验证，当前运行稳定，无需在本轮追加微调，本轮不予启动。

---

## 10. Explicit Frozen Boundaries (Strict Invariants)

在 C1 与 C2 的实施全过程中，以下区域**严格绝对冻结**：

| 子系统 / 模块 | 冻结红线规则 |
| :--- | :--- |
| **保存与持久化底层** | 严格保留当前真实保存调用：`editor.save()`、`editor.save(lockLyrics: true, lockTranslation: true)`、`lyricsEditorSession.onSaved`、`PlaybackState.applyLyricsEditorResult(...)`。严禁新增保存模式，严禁重构 SQLite schema。 |
| **键盘输入行为** | 严禁劫持 `Space` 键作为播放/暂停快捷键，TextField 内打字必须维持 macOS 原生 Space 输入行为。 |
| **状态机与架构** | 严禁新增任何 editor coordinator、router 或复杂第二套状态机，严格基于现有 SessionController 进行最小收敛。 |
| **Main Window V3 基线** | `AppleMusicImmersiveV3WindowView.swift`、Ambient/Stage/Classic 布局、着色器与排版 100% 绝对冻结。 |
| **V3 Main Toolbar** | 工具栏胶囊、断点菜单、视觉调节 Popover 100% 绝对冻结。 |
| **Provider & Recovery** | 状态指示灯、网络 Provider、`SongSearchPopover`、Manual Import 流程 100% 绝对冻结。 |
| **Settings Center** | 设置中心 5 大分类导航结构与各页面内容 100% 绝对冻结。 |
| **PresentationClock** | 播放呈现时钟引擎与平滑过渡 100% 绝对冻结。 |
| **C3 / C4 / C5 范围** | `personal-library-activity`、MenuBar、Floating、Capsule 100% 暂缓，严禁触碰。 |

---

## 11. Verification Strategy

针对 C1 与 C2 的逐步执行：
1. **静态检查**:
   ```bash
   git diff --check origin/main...HEAD
   ```
   必须无格式、空白或语法错误。
2. **Xcode 编译验证**:
   ```bash
   xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/spotifylyrics-other-windows-dd build
   ```
   必须输出 `** BUILD SUCCEEDED **`。
3. **主工作区保护**:
   确保 `/Users/apple/backup/sptifylyrics` 保持未修改、未触碰。
4. **运行时实机验证**:
   对 C1 进行视觉审查，对 C2 依次实机验证 State 1、State 2、State 3 及系统菜单触发。

---

## 12. Stop Conditions

- **本轮仅输出当前 Implementation Plan 修订并提交文档 commit**，严禁在当前 turn 编写任何 Swift 代码。
- 在用户审查并明确批准本 Plan 前，不得启动 C1 实施。
- 在 C1 验收通过并获准前，不得启动 C2 实施。
- 绝不启动已暂缓的 C3、C4、C5。

---
*Implementation Plan Status: Ready for Review (`OTHER_WINDOWS_P0_PLAN_REVISION_2=READY_FOR_REVIEW`)*

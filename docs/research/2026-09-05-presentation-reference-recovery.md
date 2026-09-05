# 灵动岛与桌面歌词参考恢复审计

日期：2026-09-05。源码审计基线：`fb95a9eaa6555d0dbccdf1fa9287bd2125c6ef16`，实施分支 `codex/experience-restoration`。本报告只读研究参考实现与基线源码，未运行参考应用、未访问用户媒体库、未复制外部代码或素材。本轮仅写本报告；实施中的并行修改不属于下面的基线缺口结论。

用户本轮已授权恢复可开启且好用的灵动岛，并完善桌面歌词及主窗口三种风格。旧报告的阶段限制是历史背景，不能代替本轮授权。当前范围以用户本轮明确要求为准，Obsidian 保存交接；Craft 已退役，不参与当前范围判断。

## 1. 找回的历史位置

六个参考目录均仍在正式项目根下的 `.local/reference-projects/`。它们是只读参考快照，不是当前产品源码，目录名称也不能证明上游版本新旧。

| 目录（相对 `/Users/apple/backup/sptifylyrics/.local/reference-projects/`） | README 身份与本地 LICENSE | 最有用的实现位置 |
| --- | --- | --- |
| `DynamicNotch-main` | 实际产品名 **NotchDrop**，文件投递工具；MIT | `NotchDrop/Ext+NSScreen.swift`、`NotchWindowController.swift`、`NotchViewModel+Events.swift`、`NotchView.swift` |
| `boring.notch-main` | Boring Notch，音乐与系统辅助岛；GPL-3.0 文本 | `boringNotch/ContentView.swift`、`models/BoringViewModel.swift`、`sizing/matters.swift`、`components/Notch/NotchShape.swift` |
| `Atoll-dev` | Atoll，macOS Dynamic Island；GPL-3.0 文本 | `DynamicIsland/ContentView.swift`、`sizing/matters.swift`、`components/Notch/NotchShape.swift` |
| `LyricsX-master` | MxIris 维护分支的 LyricsX；MPL-2.0 | `LyricsX/Controller/KaraokeLyricsController.swift`、`View/KaraokeLyricsView.swift`、`LyricsHUD/LyricsHUDViewController.swift` |
| `TaskbarLyrics-main` | Windows 任务栏双行歌词；MIT | `TaskbarLyrics.App/Web/Lyrics/index.html`、`LyricsWindowHost.cs`、`docs/WebView界面视觉与交互规范.md` |
| `Mineradio-main` | Windows 沉浸式音乐播放器；GPL-3.0 文本 | `public/desktop-lyrics.html`、`public/css/index.css`、`public/index.html` |

以上许可证来自各快照根部 LICENSE 的标题，不是对移植或再分发条件的法律结论。本轮只提炼行为并独立实现，不搬运代码、图标、配色或品牌素材。

仓库历史报告：`docs/research/UI_REFERENCE_AUDIT.md`（2026-07-26，旧基线 e24fbb3）及 `docs/REFERENCE_PROJECTS_LYRICS_AUDIT.md`（2026-07-30，旧基线 63b555d）。前者保存 Dynamic Lyrics 主窗口、全屏与辅助窗口的观察，明确说明透明辅助窗口截图不能证明可见歌词，胶囊动画时长未测得；后者是歌词来源审计，不是本轮 UI 禁令。报告中旧根部参考目录现应定位到 `.local/reference-projects/`。历史 DerivedData、旧 app、截图均不能标记为当前源码或当前验收结果。

## 2. 灵动岛应借鉴的行为

### 几何先于外观

NotchDrop 的 `Ext+NSScreen.swift:11` 用 safe-area 顶部高度和左右 auxiliaryTop 区域推导硬件刘海尺寸；`NotchWindowController.swift:23` 起在无刘海屏提供后备尺寸，以 `screen.frame` 锚定屏幕物理顶边。Boring 的 `sizing/matters.swift:39` 和 Atoll 的同名文件 `:310` 同样按目标显示器求尺寸，区分真实刘海高度、菜单栏高度及无刘海显示器。

Boring `ContentView.swift:423` 与 Atoll `ContentView.swift:1249` 的闭合音乐内容保留中央硬件宽度，把可读信息放到两侧。可借鉴的是“中央硬件区不可放文字或按钮”的布局原则，而非某个固定宽度。展开内容应落在硬件刘海底边以下。几何需要支持外接显示器非零/负坐标、缩放及显示器重连。

### 可取消的进入、展开与收起

NotchDrop `NotchViewModel+Events.swift` 是进入轻微预览、点击展开、外部点击收起的三态模型。Boring `ContentView.swift:513` 的 hover 进入会取消旧任务，达到驻留时间才打开，离开延迟 100ms 再关闭，并避免活动弹出层造成误收起。Atoll `ContentView.swift:408` 起明确处理顶边普通 onHover 不可靠的后备检测，且将阴影 padding 放在交互区域外；`:2028` 起处理键盘打开后鼠标尚未进入、因此没有 hover-out 的情况。

建议本项目保留自身三态信息架构，增加可预期的 hover 到完整控制/歌词区域；使用一次可取消延迟，快速离开再进入不得被旧任务收起。点击、键盘开启与 hover 开启需要一致退出入口。透明包络、阴影与空白区域不能拦截菜单栏或其他应用；进度拖动与弹出控件交互期间不能误收起。

### 当前源码缺口（基线）

- `SpotifyLyrics/Lyrics/CapsuleLyricsPresentation.swift:20` 的 current 仍是 `controlFocusedV2`，v4 不是正式默认路径。
- `SpotifyLyrics/Windows/CapsuleLyricsWindowController.swift` 中 `debugTopAttachedEnvelope`、物理顶边 frame、`.statusBar` 层级和包络鼠标穿透检测仅在 DEBUG 分支。正式路径仍 `.floating`，其自身注释已记录该层级可能被菜单栏限制到 visibleFrame。
- `pointerEntered()` 只到 hover；正式 expanded 退出主要依赖外部点击；DEBUG 顶边鼠标逻辑又有不同退出方式。恢复为产品体验需要统一，而非只打开一个调试开关。
- v4 的封面/标题沿固定左锚排列、包络尺寸是常量。仅把 v4 设为 current 无法证明真实刘海中央避让成立。
- 已有单一 WindowController、共享 PlaybackState、歌词会话投影、全屏临时隐藏与恢复路径值得保留；不用另建播放器/计时器。

## 3. 桌面歌词与三种主窗口风格

LyricsX `KaraokeLyricsController.swift:110` 起明确区分单行、原文加翻译、原文加下一句；有歌曲/当前行缺失时清空旧句、暂停可选隐藏。窗口按 visibleFrame 或全屏 frame 放置，跨屏拖动重新求坐标。其 `LyricsHUDViewController.swift:113` 支持歌词双击 seek，手动滚动暂停自动跟随；注意 HUD 的“锁”切换窗口层级，不应误称为桌面点击穿透。

TaskbarLyrics README 明确双行与翻译、可调字体/阴影/宽度/置顶。其视觉规范 `:310` 起要求动效可中断、快速操作不积累过期回调、减少动态效果时立即切换；不照搬 Windows 的像素及 CSS 数值。

Mineradio `public/desktop-lyrics.html` 显示显式锁定/解锁状态、解锁拖动、按需出现操作提示，以及 close 入口。适合借鉴“穿透之后仍有清楚恢复入口”。README 的歌词舞台与环境视觉可作为概念参考；本报告未启动它测量舞台动态，不能把源码中的任意 object-fit 规则当完整封面的设计证明。

当前 `FloatingLyricsView` 已有透明/轻材质背景、hover 工具条、共享歌词行与减少动态效果支持；Controller 已有 interactive/locked/passThrough 三模式、位置保存和屏幕 clamp。待完善的是窄高窗口下原文/译文/注音的可读性、锁定之后恢复操作可发现性、长句不裁切、hover 工具条不覆盖歌词。当前层数由共享偏好决定，不能让多个辅助层抢满小窗口。

三种主窗口风格应有清晰不同的读歌方式：环境光以封面取色与柔和背景承托歌词；封面舞台展示完整封面及歌曲信息，歌词在独立可读区域；经典放大把主要空间分配给当前歌词和邻行。**完整封面是用户直接要求**，建议使用保持原图比例的 fit、周围留白/背景补足，不能用放大裁切的背景图替代前景封面。窄窗应重新布局或缩小封面，不能裁掉封面边缘。该要求无需引用旧参考项目证明。

## 4. 建议验收清单

1. 正式菜单/设置可开启灵动岛，关闭、重启恢复、全屏临时隐藏及返回一致；不依赖 DEBUG 参数。
2. 刘海屏、无刘海屏、外接屏负坐标与重连：顶边位置正确，中央刘海不遮任何可读文字/按钮，展开下缘内容完整。
3. 连续快速进入/离开至少 10 次、点击展开、外部点击、键盘开启、进度拖动后退出：不闪烁、不残留透明挡板、不执行过期收起任务。
4. 岛外菜单栏与其他窗口可点击；岛内上一首、播放暂停、下一首、seek 只触发一次。切歌/无歌词/加载/暂停不显示前曲残留歌词。
5. 桌面歌词在短窗口、长日语/中英句、译文加注音、大字号与不同背景上人工截图检查；清楚显示当前行，不截关键辅助文字，工具条不遮挡。
6. 锁定与穿透后可通过正式菜单解锁；跨屏移动、尺寸改变、重启恢复仍在可见区。
7. 环境光、封面舞台、经典放大逐一在最小窗、常用窗、全屏验收；用四边带标记的测试封面确认舞台完整显示原图边缘，歌词保持独立对比度。
8. 开启系统减少动态效果再切歌、hover、切风格；视觉变化及时且无持续不必要动画。记录构建来源、真实窗口截图和人工交互结果；本报告的只读研究不能替代运行验收。

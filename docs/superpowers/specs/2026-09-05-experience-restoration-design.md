# Experience restoration

User request: 去修吧，顺便把灵动岛做回来，我记得给过很多参考的项目，的，你翻翻能不能找到历史位置，现在还在仓库的文件夹里，再把桌面歌词也做好，还有3种风格也好好做好，比如封面舞台现在的背景还不是完整的封面，有问题你就自己多轮迭代

This explicitly reopens capsule, desktop lyrics and the three V3 artwork presentations. User authorized autonomous iteration; previous freeze decisions do not limit this work. Existing main fb95a9e is the implementation base, not an older backup. Primary dirty checkout is protected.

## Required end state

1. Review findings fixed: preview candidate adopts into the presented session; MenuBar Settings uses SwiftUI settings routing; history SQLite errors propagate; history/statistics show real failures and retry without discarding last good values; broken contract source manifests restored. New tests exercise real production behavior and failure recovery.
2. References located and documented from .local/reference-projects; study DynamicNotch, boring.notch, Atoll and desktop lyrics references. No wholesale restoration from backups or copying external implementation into proprietary source.
3. Dynamic Island is available through normal product settings/menu in Debug and Release, compact at screen top, avoids physical notch content occlusion, expands on intentional hover/click, supports play/pause/previous/next and current lyrics, collapses predictably and handles non-notch/external displays. Transparent unused host areas do not steal clicks.
4. Desktop lyrics: legible active line and optional companion layers, sensible resizing, hover controls without text overlap, drag/lock/pass-through with reachable recovery, correct paused/loading/no-lyrics states, shared live playback session. No independent timer/provider.
5. V3 ambient/stage/classic: clearly distinct working compositions. Ambient uses cover color field with complete foreground cover; stage shows one uncropped complete cover (all four edges, aspect preserved) with readable lyrics and integrated controls; classic keeps intentionally enlarged background but stable readable foreground. Size/position/blur controls work honestly. Missing/portrait/landscape/bright artwork and compact sizes have bounded layout.
6. Iterate using actual rendered windows and focused runtime/geometry tests. Check normal and compact sizes, notched/non-notched geometry, long multilingual lyrics, no artwork, pauses/track transitions, Reduce Motion. Build Debug and Release before delivery; report exactly which real-playback checks occurred. Deliver runnable review build and source commits without replacing frozen releases.

## Architecture and scope

Use existing PlaybackState, LyricsSessionController and repository. Keep rendering/window geometry separate from playback. Use current controllers and presentation catalog rather than add parallel products. Add narrow helper types only when they improve testable geometry/load state. Keep compatibility stable IDs and user data/settings; migrate only obsolete prototype availability where necessary. No file-drop/calendar/notification features borrowed from reference notch apps.

## Validation boundary

A source-string contract cannot prove visual quality. Render and inspect each user-facing surface with deterministic temporary fixtures, then verify product routes. Never operate the real user database as test storage. Tests/probes must record source SHA and isolated data path. Known gate-repository save-binding risk is not yet a proven product failure; investigate only as it affects touched session behavior.

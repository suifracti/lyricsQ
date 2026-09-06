# Hover, ruby, desktop and seek investigation — 2026-09-06

Checkpoint85e99ec on feature branch codex/lyrics-search-ambient-fix; formal root untouched. Current user clarifies final seek symptom: click/drag has no effect and Spotify does not receive jump (supersedes earlier mistaken statement that Spotify jumped).

- Read-only live DB: アーカイブ - Piano Ver.21.670–24.333 line既読の速度で愛はかって lacks stored readings; no readingversions/wordtimingversions. MeCab split既/読 yielded unknown読, full-linekana nil; oldV3 gate hidknownannotations too.
- Shared JapaneseRubyPresentation now preserves confirmedpartialruby and exactalignment, adds established既読 compound handling, shares timedLayout between main anddesktop. Genuine timedspans drive clock-basedfill; no guessed timestamps persisted. Current song remains without exactwordtiming.
- Optional persisted hover-only metadata/transport: defaultoff, pointerinsidewindow oractivepopover/drag reveals; leavefades hit-disabled controls. Foregroundcover modest bounded transform, lyricgeometry unchanged, reduce-motion skips transform.
- Desktop has5role customcolors, crisp attributedglyphoutline and measuredannotation clearance, optionalopaque text independent frombackgroundopacity; presets/restoration remain.
- Seek initial red/greenorder-robustness fix alone didnot reproduce userproblem. Native probe showed normalclick ordering. Actual CUA drag laterproduced no callbacks inwindow movablebybackground: investigation remainsactive, no prematurefixedclaim.
- Integrated Debug PASS: xcodebuild -project SpotifyLyrics.xcodeproj -scheme SpotifyLyrics -configuration Debug -derivedDataPath /tmp/lyrics-hover-desktop-debug CODE_SIGNING_ALLOWED=NO build.
- Fullsourceisolatedhost buildPASS. Focused ruby/realspanclock and desktopcolor/outline/windowcontractsPASS per agents; native integration/seekfix next.

### Native integration findings
- Full V3 native host now exposes 既=き / 読=どく, verified in AX and rendered image `/tmp/lyrics-ruby-seek-integrated.png`. Additional root cause was stale noncontextual enrichment winning over generated contextual tokens; shared selection now only prioritizes explicitly selected reading versions.
- Full V3 click at the custom rail changed18to119.006sec and fake provider logged the same command. Automated drag still committed its old position, despite standalone long pointer tracking logs; seek repair therefore remains under investigation. No real Spotify seek or production DB write was used.
- Shared desktop timing font measurements now match rendered default NSFont; main retains rounded design. Real CoreText metric and sweep-boundary regression passes.

### First-batch verification checkpoint
- Final fullhost native pointer verification PASS: forward drag18→165.5814, reverse→41.5504, click→19.8450sec; AX position and fake provider VISUAL_SEEK agreed, and lyrics returned to the correct early row. Dedicated probe additionally verifies sparse mouseUp final coordinates and one commit per gesture. See v3-seek-input-verification.md.
- Desktop360×120 custom palette/ruby on white backdrop rendered at18and20sec using real fixture spans; bounded outline/annotations visible, fill changes with time. Main ambient realspan screenshot18sec shows partial white progress with top ruby. Hover-hidden ambient removes metadata/transport from both native image and AX; other styles use shared visibility, final full-screen validation follows.
- Latest Debug and fullsource native host builds PASS after pointer-loop and font-metric fixes. Required readability, ruby restoration, pointer/draft, presentationclock, rubyprojection, responsivegeometry, glyphoutline and floatingwindow contracts PASS. No real Spotify interaction was used for automated tests.
- No-timing songs remain line-level (no estimated timing selected/added). Native allstyle fullscreen and final Release delivery belong to queued next batch.

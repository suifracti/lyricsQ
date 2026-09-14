# V3 lyric motion stability

Date: 2026-09-14
Status: implemented on `grok/v3-lyric-motion-stability` (not merged)

## Problem

Main V3 felt janky. Lyric wrap during line follow, becoming current, and window resize looked yanked.

Root cause: `withAnimation` around `scrollTo` interpolated wrap/weight/height; active rows used a heavier weight that moved break points; layoutSignature used a 0.34s wrap interpolation; timed rows swapped structure on activation; the lyrics subtree observed `PlaybackState` including 5 Hz `currentTime`.

## Contract

V3 main lyrics only. Desktop, capsule, and the editor are unchanged.

- Wrap depends on text + width + shared reading weight. Active state does not change size, weight, or break points.
- Emphasis is opacity/color only.
- Line follow is 0.40s easeInOut, deferred off the layout transaction.
- Resize rebreaks immediately. `layoutSignature` is not interpolated.
- Timed rows keep the same visual lines when inactive; only the active row runs the 60fps fill clock.
- Seek, track change, and version change remain immediate.
- Reduce Motion: no follow displacement.

## Implementation map

- `V3LyricMotionPolicy` in `LyricsDesignTokens.swift`
- `AppleMusicImmersiveV3LyricsDocumentView` skips equal playback-tick refreshes
- Progress and time labels read `presentationClock` through `TimelineView`

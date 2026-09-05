# Stage Background Correction Implementation Plan

**Goal:** Implement the user's confirmed full-background cover stage.
**Architecture:** Reuse the existing background loader, lyrics viewport and HUD; change only stage geometry/composition and obsolete validation assumptions.
**Execution:** One local task, with independent review after the patch.

- [ ] Replace old non-overlap geometry assertions with full-canvas coverage and aspect-independent lyric viewport assertions; confirm red.
- [ ] Change stage artwork to aspect-fill background, subtle veil and centered overlay lyrics; remove no-longer-needed aspect callback and tiny-band projection.
- [ ] Run geometry/composition/readability contracts and production builds; inspect wide and compact native images.
- [ ] Review, commit/push, package distinct preview and update handoff with corrected definition.

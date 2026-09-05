# Cover-shaped stage window

User explicitly selected a window that follows the complete cover's proportions instead of wide-window extensions. Apply only to the main V3 stage; keep lyrics unchanged. Use the existing decoded image aspect (no second download). Fit and center the window within its current screen, constrain manual resizing to that ratio, release the constraint on leaving stage. Fullscreen follows the display and retains complete-image fitting.

- Verify aspect-fitted window geometry across screen/image ratios.
- Add a main-stage-only window accessor, restore constraints on detach, and pass decoded aspect from backdrop.
- Build and inspect the native square stage; record results and deliver distinct preview.

Previous complete-cover commit 3773ef7 is local; two pushes failed (HTTP2 framing, empty reply). Keep reversible local checkpoints; retry remote sync without rewriting history.

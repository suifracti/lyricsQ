# Complete stage cover

User approved full artwork with background extension, and explicitly scoped this step to background only. Entire image must remain visible at all window aspect ratios; no stretching or cropping of the primary image. Center an aspect-fit original above a blurred aspect-fill duplicate. Stage ignores legacy zoom/position settings; remove those stage controls. Keep lyrics unchanged.

- Change geometry contract to require containment, centering, original proportions and independence from persisted zoom/position; confirm red.
- Implement fitted primary image and blurred extension; remove misleading stage controls.
- Run geometry/style checks, Debug/Release builds, inspect native preview.
- Record validation, commit/push, update current handoff and open distinct preview.

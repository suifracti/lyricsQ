# Findings

Base fb95a9e. Four review findings located in previous report /private/tmp/spotifylyrics-review-20260905/docs/audits/2026-09-05-reliability-review/REPORT.md.
References found under primary .local/reference-projects: DynamicNotch-main, boring.notch-main, Atoll-dev, LyricsX-master, TaskbarLyrics-main, Mineradio-main.
Current three styles are V3ArtworkPresentation ambient/stage/classic. Stage already has an aspect-fit plane but also high blur/layout dependencies; must render to determine actual complaint rather than assume scaledToFit alone satisfies it.

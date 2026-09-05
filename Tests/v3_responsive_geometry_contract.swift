import Foundation

@main
struct V3ResponsiveGeometryContract {
    static func main() {
        precondition(
            V3ResponsiveGeometry.layoutRegime(canvasSize: CGSize(width: 760, height: 520)) == .compact,
            "technical minimum must use the compact regime"
        )
        precondition(
            V3ResponsiveGeometry.layoutRegime(canvasSize: CGSize(width: 1_040, height: 680)) == .regular,
            "reference window must use the regular regime"
        )
        precondition(
            V3ResponsiveGeometry.layoutRegime(canvasSize: CGSize(width: 1_440, height: 900)) == .wide,
            "large canvas must use the wide regime"
        )

        // A user who leaves automatic lyrics focus disabled expects one
        // continuously resizing V3 composition. The former small-window
        // poster replaced the entire split layout at 800x600 and made a
        // one-point drag look like uncontrolled zooming.
        for size in [
            CGSize(width: 760, height: 520),
            CGSize(width: 799, height: 599),
            CGSize(width: 800, height: 599),
            CGSize(width: 800, height: 600),
            CGSize(width: 1_079, height: 599),
            CGSize(width: 1_080, height: 599),
            CGSize(width: 1_760, height: 1_174)
        ] {
            precondition(
                V3ResponsiveGeometry.foregroundLayout(
                    canvasSize: size,
                    automaticLyricsFocus: false
                ) == .adaptiveSplit,
                "manual V3 must keep one continuous split composition at \(size)"
            )
        }

        precondition(
            V3ResponsiveGeometry.foregroundLayout(
                canvasSize: CGSize(width: 860, height: 620),
                automaticLyricsFocus: true
            ) == .lyricsFocus,
            "automatic lyrics focus remains an explicit compact-window behavior"
        )

        let narrowCover = V3ResponsiveGeometry.boundedCoverSize(
            availableWidth: 170,
            availableHeight: 120,
            desiredSize: 300,
            minimum: 180
        )
        precondition(narrowCover <= 120.001, "cover must not exceed the narrowest available dimension")

        let split = V3ResponsiveGeometry.splitColumns(
            containerWidth: 760,
            requestedArtworkRatio: 0.45,
            gap: 28,
            minimumArtworkWidth: 220,
            minimumLyricsWidth: 300
        )
        precondition(abs(split.artwork + split.lyrics + split.gap - 760) < 0.001, "columns must fill the container exactly")
        precondition(split.artwork >= 0 && split.lyrics >= 0 && split.gap >= 0, "columns must never be negative")
        precondition(split.lyrics >= 300 - 0.001, "lyrics must retain a readable minimum when the container allows it")

        // A one-point resize across the former 1080pt breakpoint must not
        // replace the split composition with a poster or suddenly reallocate
        // a large part of the canvas to artwork. These expectations are
        // deliberately derived from continuity and containment, not from the
        // implementation's interpolation formula.
        let beforeWideBoundary = V3ResponsiveGeometry.adaptiveSplitMetrics(
            canvasSize: CGSize(width: 1_079, height: 720),
            artworkScale: 1.4
        )
        let afterWideBoundary = V3ResponsiveGeometry.adaptiveSplitMetrics(
            canvasSize: CGSize(width: 1_081, height: 720),
            artworkScale: 1.4
        )
        precondition(
            abs(beforeWideBoundary.artworkWidth - afterWideBoundary.artworkWidth) < 4,
            "artwork column must change continuously across the former wide breakpoint"
        )
        precondition(
            abs(beforeWideBoundary.coverSize - afterWideBoundary.coverSize) < 4,
            "cover size must change continuously across the former wide breakpoint"
        )

        for size in [
            CGSize(width: 800, height: 600),
            CGSize(width: 1_080, height: 720),
            CGSize(width: 1_760, height: 732)
        ] {
            let metrics = V3ResponsiveGeometry.adaptiveSplitMetrics(
                canvasSize: size,
                artworkScale: 1.4
            )
            precondition(
                abs(metrics.artworkWidth + metrics.lyricsWidth + metrics.gap - metrics.contentWidth) < 0.001,
                "adaptive split columns must fill the available width exactly"
            )
            precondition(
                metrics.coverSize <= metrics.artworkWidth - 12 + 0.001,
                "cover must remain inside its artwork column at 140 percent"
            )
            precondition(
                metrics.coverSize + metrics.reservedTrackChromeHeight <= metrics.availableHeight + 0.001,
                "cover, metadata and transport must remain inside the visible height"
            )
        }

        for canvas in [CGSize(width: 760, height: 520), CGSize(width: 1040, height: 680), CGSize(width: 1440, height: 900), CGSize(width: 760, height: 1000)] {
            let bounds = CGRect(origin: .zero, size: canvas)
            for aspect: CGFloat in [0.2, 0.65, 1, 1.8, 5] {
                let small = V3ResponsiveGeometry.stageArtworkRect(canvasSize: canvas, artworkAspectRatio: aspect, requestedScale: 0.8)
                let large = V3ResponsiveGeometry.stageArtworkRect(canvasSize: canvas, artworkAspectRatio: aspect, requestedScale: 1.4)
                precondition(small == large, "saved zoom cannot crop the complete stage cover")
                for position in ["left", "center", "right"] {
                    let cover = V3ResponsiveGeometry.stageArtworkRect(canvasSize: canvas, artworkAspectRatio: aspect, requestedScale: 0.8, position: position)
                    precondition(abs(cover.midX - bounds.midX) < 0.001 && abs(cover.midY - bounds.midY) < 0.001, "complete cover stays centered regardless of saved position")
                    precondition(abs(cover.width - canvas.width) < 0.001 || abs(cover.height - canvas.height) < 0.001, "cover uses the largest uncropped fit")
                    let reading = V3ResponsiveGeometry.stageReadingRect(canvasSize: canvas, artworkAspectRatio: aspect, position: position)
                    precondition(bounds.insetBy(dx: -0.001, dy: -0.001).contains(cover), "entire source image must stay inside the stage")
                    precondition(abs(cover.width / cover.height - aspect) < 0.001, "background preserves source proportions")
                    precondition(bounds.contains(reading) && reading.height > canvas.height * 0.5, "lyrics overlay gets the central stage, not a lower band")
                    precondition(reading == V3ResponsiveGeometry.stageReadingRect(canvasSize: canvas, artworkAspectRatio: 1, position: "center"), "lyrics position must not depend on cover orientation")
                }
            }
        }

        print("V3 responsive geometry contract: PASS")
    }
}

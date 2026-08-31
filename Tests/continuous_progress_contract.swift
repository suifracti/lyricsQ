import Foundation

@main
struct ContinuousProgressContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() throws {
        // 1. Single span: 1.0 -> 3.0
        print("[1] Testing single span progress: 1.0s -> 3.0s...")
        let _ = TimedTextSpan(id: 0, text: "Test", trailingWhitespace: "", startTime: 1.0, endTime: 3.0, utf16Start: 0, utf16Length: 4, granularity: .timedUnit)

        let p0 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 0.0)
        assertRule(p0 == 0.0, "t=0.0 -> progress must be 0.0, got \(p0)")

        let p1 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 1.0)
        assertRule(p1 == 0.0, "t=1.0 -> progress must be 0.0, got \(p1)")

        let p1_5 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 1.5)
        assertRule(abs(p1_5 - 0.25) < 1e-6, "t=1.5 -> progress must be 0.25, got \(p1_5)")

        let p2 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 2.0)
        assertRule(abs(p2 - 0.5) < 1e-6, "t=2.0 -> progress must be 0.5, got \(p2)")

        let p2_5 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 2.5)
        assertRule(abs(p2_5 - 0.75) < 1e-6, "t=2.5 -> progress must be 0.75, got \(p2_5)")

        let p3 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 3.0)
        assertRule(p3 == 1.0, "t=3.0 -> progress must be 1.0, got \(p3)")

        let p4 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 4.0)
        assertRule(p4 == 1.0, "t=4.0 -> progress must be 1.0, got \(p4)")

        // 2. Seek backward: non-monotonic time inputs must produce non-monotonic progress (pure function, no animation state)
        print("[2] Testing seek backward idempotency and pure function semantics...")
        let pForward = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 2.8)
        let pBackward = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 1.2)
        assertRule(abs(pForward - 0.9) < 1e-6, "t=2.8 -> progress must be 0.9")
        assertRule(abs(pBackward - 0.1) < 1e-6, "t=1.2 -> progress must be 0.1")
        assertRule(pBackward < pForward, "Seeking backward must produce smaller progress without animation hysteresis")

        // 3. Pause: repeated calls at same currentTime must return identical results
        print("[3] Testing pause invariance...")
        let pPause1 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 2.0)
        let pPause2 = TimedTextComposer.calculateSpanProgress(startTime: 1.0, endTime: 3.0, currentTime: 2.0)
        assertRule(pPause1 == pPause2, "Paused progress must remain identical")

        // 4. Multi span with untimed whitespace and punctuation
        print("[4] Testing multi-span 'Hello World!' composition...")
        let multiSpans = [
            TimedTextSpan(id: 0, text: "Hello", trailingWhitespace: " ", startTime: 1.0, endTime: 2.0, utf16Start: 0, utf16Length: 5, granularity: .timedUnit),
            TimedTextSpan(id: 1, text: "World", trailingWhitespace: "", startTime: 2.0, endTime: 3.0, utf16Start: 6, utf16Length: 5, granularity: .timedUnit)
        ]
        let originalText = "Hello World!"

        let segsBefore = TimedTextComposer.composeSegments(displayText: originalText, originalText: originalText, spans: multiSpans, currentTime: 0.5)
        assertRule(segsBefore.count == 4, "Expected 4 segments: Hello, space, World, !")
        assertRule(segsBefore[0].progress == 0.0 && !segsBefore[0].isPlayed && !segsBefore[0].isActive, "Hello before start must have progress 0")
        assertRule(segsBefore[1].progress == 0.0, "Space before start must have progress 0")
        assertRule(segsBefore[2].progress == 0.0, "World before start must have progress 0")
        assertRule(segsBefore[3].progress == 0.0, "! before start must have progress 0")

        let segsMid1 = TimedTextComposer.composeSegments(displayText: originalText, originalText: originalText, spans: multiSpans, currentTime: 1.5)
        assertRule(abs(segsMid1[0].progress - 0.5) < 1e-6 && segsMid1[0].isActive, "Hello at 1.5s must be active with progress 0.5")
        assertRule(segsMid1[1].progress == 0.0, "Space during first word is unplayed")
        assertRule(segsMid1[2].progress == 0.0, "World during first word is unplayed")

        let segsMid2 = TimedTextComposer.composeSegments(displayText: originalText, originalText: originalText, spans: multiSpans, currentTime: 2.5)
        assertRule(segsMid2[0].progress == 1.0 && segsMid2[0].isPlayed, "Hello at 2.5s must be played (progress 1.0)")
        assertRule(segsMid2[1].progress == 1.0 && segsMid2[1].isPlayed, "Space at 2.5s must be played (progress 1.0)")
        assertRule(abs(segsMid2[2].progress - 0.5) < 1e-6 && segsMid2[2].isActive, "World at 2.5s must be active with progress 0.5")
        assertRule(segsMid2[3].progress == 0.0, "! before line end is unplayed")

        let segsAfter = TimedTextComposer.composeSegments(displayText: originalText, originalText: originalText, spans: multiSpans, currentTime: 3.5)
        assertRule(segsAfter.allSatisfy { $0.progress == 1.0 && $0.isPlayed }, "All segments after line completion must have progress 1.0")

        // 5. Malformed timing protection: equal start/end and end < start
        print("[5] Testing malformed timing protection (zero duration, inverted timestamps)...")
        let pZeroBefore = TimedTextComposer.calculateSpanProgress(startTime: 2.0, endTime: 2.0, currentTime: 1.9)
        let pZeroAt = TimedTextComposer.calculateSpanProgress(startTime: 2.0, endTime: 2.0, currentTime: 2.0)
        let pZeroAfter = TimedTextComposer.calculateSpanProgress(startTime: 2.0, endTime: 2.0, currentTime: 2.1)
        assertRule(pZeroBefore == 0.0, "Zero duration before timestamp must be 0.0")
        assertRule(pZeroAt == 1.0, "Zero duration at timestamp must be 1.0")
        assertRule(pZeroAfter == 1.0, "Zero duration after timestamp must be 1.0")
        assertRule(!pZeroBefore.isNaN && !pZeroAt.isNaN && !pZeroAfter.isNaN, "Zero duration must never produce NaN")

        let pInvertedBefore = TimedTextComposer.calculateSpanProgress(startTime: 3.0, endTime: 2.0, currentTime: 2.5)
        let pInvertedAt = TimedTextComposer.calculateSpanProgress(startTime: 3.0, endTime: 2.0, currentTime: 3.0)
        assertRule(pInvertedBefore == 0.0, "Inverted timestamps before start must be 0.0")
        assertRule(pInvertedAt == 1.0, "Inverted timestamps at/after start must be 1.0")
        assertRule(!pInvertedBefore.isNaN && !pInvertedAt.isNaN, "Inverted timestamps must never produce NaN")

        print("PASS: Continuous progress contract verified")
    }
}

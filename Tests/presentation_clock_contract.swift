import Foundation

// Test contract for LyricsPresentationClock

@main
struct PresentationClockContract {
    static func main() {
        print("=== PRESENTATION CLOCK CONTRACT ===")

        // 1. Playing + 100ms -> +0.1s
        print("[1] Testing playing monotonic advancement...")
        let clock1 = LyricsPresentationClock(
            authoritativePosition: 10.0,
            receivedAtMonotonicTime: 100.0,
            isPlaying: true,
            trackID: "track1",
            trackDuration: 200.0
        )
        let t1_0 = clock1.presentationTime(at: 100.0)
        let t1_1 = clock1.presentationTime(at: 100.1)
        let t1_5 = clock1.presentationTime(at: 100.5)
        assert(abs(t1_0 - 10.0) < 1e-6, "t1_0 should be 10.0, got \(t1_0)")
        assert(abs(t1_1 - 10.1) < 1e-6, "t1_1 should be 10.1, got \(t1_1)")
        assert(abs(t1_5 - 10.5) < 1e-6, "t1_5 should be 10.5, got \(t1_5)")

        // 2. Pause -> time fixed
        print("[2] Testing paused clock invariance...")
        let clock2 = LyricsPresentationClock(
            authoritativePosition: 10.5,
            receivedAtMonotonicTime: 100.5,
            isPlaying: false,
            trackID: "track1",
            trackDuration: 200.0
        )
        let t2_0 = clock2.presentationTime(at: 100.5)
        let t2_1 = clock2.presentationTime(at: 101.0)
        let t2_5 = clock2.presentationTime(at: 105.0)
        assert(abs(t2_0 - 10.5) < 1e-6, "t2_0 should be 10.5, got \(t2_0)")
        assert(abs(t2_1 - 10.5) < 1e-6, "t2_1 should be 10.5, got \(t2_1)")
        assert(abs(t2_5 - 10.5) < 1e-6, "t2_5 should be 10.5, got \(t2_5)")

        // 3. Resume -> starts advancing from new anchor
        print("[3] Testing resume from new anchor...")
        let clock3 = LyricsPresentationClock(
            authoritativePosition: 10.5,
            receivedAtMonotonicTime: 105.0,
            isPlaying: true,
            trackID: "track1",
            trackDuration: 200.0
        )
        let t3_0 = clock3.presentationTime(at: 105.0)
        let t3_2 = clock3.presentationTime(at: 105.2)
        assert(abs(t3_0 - 10.5) < 1e-6, "t3_0 should be 10.5, got \(t3_0)")
        assert(abs(t3_2 - 10.7) < 1e-6, "t3_2 should be 10.7, got \(t3_2)")

        // 4. Seek forward -> instant jump
        print("[4] Testing seek forward...")
        let clock4 = LyricsPresentationClock(
            authoritativePosition: 45.0,
            receivedAtMonotonicTime: 106.0,
            isPlaying: true,
            trackID: "track1",
            trackDuration: 200.0
        )
        let t4_0 = clock4.presentationTime(at: 106.0)
        let t4_3 = clock4.presentationTime(at: 106.3)
        assert(abs(t4_0 - 45.0) < 1e-6, "t4_0 should be 45.0, got \(t4_0)")
        assert(abs(t4_3 - 45.3) < 1e-6, "t4_3 should be 45.3, got \(t4_3)")

        // 5. Seek backward -> instant jump
        print("[5] Testing seek backward...")
        let clock5 = LyricsPresentationClock(
            authoritativePosition: 2.0,
            receivedAtMonotonicTime: 107.0,
            isPlaying: true,
            trackID: "track1",
            trackDuration: 200.0
        )
        let t5_0 = clock5.presentationTime(at: 107.0)
        let t5_1 = clock5.presentationTime(at: 107.1)
        assert(abs(t5_0 - 2.0) < 1e-6, "t5_0 should be 2.0, got \(t5_0)")
        assert(abs(t5_1 - 2.1) < 1e-6, "t5_1 should be 2.1, got \(t5_1)")

        // 6. Track change -> reset
        print("[6] Testing track change reset...")
        let clock6 = LyricsPresentationClock(
            authoritativePosition: 0.0,
            receivedAtMonotonicTime: 108.0,
            isPlaying: true,
            trackID: "track2",
            trackDuration: 180.0
        )
        assert(clock6.trackID == "track2", "Track ID should be track2")
        assert(abs(clock6.presentationTime(at: 108.0) - 0.0) < 1e-6, "Should start at 0")

        // 7. Authoritative correction -> no old drift
        print("[7] Testing authoritative Spotify correction without historical drift...")
        // At mono=108.0, Spotify tells us pos is 0.0
        // At mono=108.5, extrapolated was 0.5
        // At mono=108.5, Spotify authoritative arrives as 0.48 (small network latency)
        let clock7_corrected = LyricsPresentationClock(
            authoritativePosition: 0.48,
            receivedAtMonotonicTime: 108.5,
            isPlaying: true,
            trackID: "track2",
            trackDuration: 180.0
        )
        let t7 = clock7_corrected.presentationTime(at: 108.5)
        assert(abs(t7 - 0.48) < 1e-6, "Correction should immediately take 0.48, got \(t7)")

        // 8. Track duration clamp
        print("[8] Testing track duration clamp...")
        let clock8 = LyricsPresentationClock(
            authoritativePosition: 199.5,
            receivedAtMonotonicTime: 100.0,
            isPlaying: true,
            trackID: "track2",
            trackDuration: 200.0
        )
        let t8_over = clock8.presentationTime(at: 102.0)
        assert(abs(t8_over - 200.0) < 1e-6, "Should clamp at duration 200.0, got \(t8_over)")

        print("PASS: Presentation clock contract verified")
    }
}

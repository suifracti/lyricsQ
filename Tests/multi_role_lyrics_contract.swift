import Foundation

@main
struct MultiRoleLyricsContract {
    private static func line(_ performerID: String?) -> LyricLine {
        LyricLine(timestamp: 0, originalText: "line", performerID: performerID)
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() {
        let noAgentMap = LyricAgentPresentationMap(lines: [line(nil), line(nil)])
        require(!noAgentMap.isActive, "lines without performerID must keep the existing presentation")
        require(noAgentMap.horizontalOffset(for: nil) == 0, "missing performerID must have no offset")

        let singleAgentMap = LyricAgentPresentationMap(lines: [line("v1"), line("v1")])
        require(!singleAgentMap.isActive, "one performerID must keep the existing presentation")
        require(singleAgentMap.horizontalOffset(for: "v1") == 0, "single performerID must have no offset")

        let explicitAgents = [line("v2"), line("v1"), line("v2"), line("opaque-agent")]
        let map = LyricAgentPresentationMap(lines: explicitAgents)
        require(map.isActive, "two or more explicit performerIDs must activate presentation")
        require(map.agentIDs == ["opaque-agent", "v1", "v2"], "agent IDs must be sorted deterministically")
        require(map.horizontalOffset(for: "opaque-agent") == 0, "first deterministic agent must use the default alignment")
        require(map.horizontalOffset(for: "v1") == 6, "second deterministic agent must use the light offset")
        require(map.horizontalOffset(for: "v2") == 12, "third deterministic agent must stay within the bounded offset")
        require(map.horizontalOffset(for: "v2") == map.horizontalOffset(for: "v2"), "repeated performerID must map identically")

        let unknown = "agent-without-semantic-meaning"
        require(map.horizontalOffset(for: unknown) == 0, "an unlisted opaque ID must fail safe")

        let reorderedMap = LyricAgentPresentationMap(lines: explicitAgents.reversed())
        require(reorderedMap == map, "mapping must not depend on line order")

        print("PASS: multi-role explicit-agent presentation contract")
    }
}
